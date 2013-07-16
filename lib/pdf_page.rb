#encoding: utf-8

require 'pdf/reader'

class PdfPage
  attr_reader :fonts, :lines
  
  def initialize(page)
    @objects = page.objects
    @fonts = enumerate_fonts(page)
    @markup_lines = walk_page(page)
    @lines = reconcile_lines(page)
  end
  
  private
    def walk_page(page)
      receiver = TextReceiver.new(@fonts)
      page.walk(receiver)
      markup_lines = receiver.content
      markup_lines.delete_if{ |x| x.strip == "" }
    end
    
    def reconcile_lines(page)
      offset = 0
      lines = []
      page.text.lines.each_with_index do |line, line_no|
        if line.strip == ""
          lines << {:plain => "", :html => ""}
        else
          markup = @markup_lines[offset]
          lines << fetch_line_data(line, markup)
          offset +=1
        end
      end
      lines
    end
    
    def fetch_line_data(line, raw_markup)
      output = ""
      return {:plain => "", :html => ""} if raw_markup.nil?
      
      @parts = raw_markup.split("</font>")
      
      @part = 0
      @matches = @parts[@part].match(/<font label='([^']+)' size='([^']+)'>([^<]*)/)
      while @matches[3].strip.empty? and @part < @parts.length-1
        @part += 1
        @matches = @parts[@part].match(/<font label='([^']+)' size='([^']+)'>([^<]*)/)
      end
      if @parts == @parts.length-1 and @matches[3].strip.empty?
        return {:plain => "", :html => ""}
      end
      output = append_font_info(output, {}, @matches[1].to_sym)
      @font = {}
      
      #iterate over all the characters in the original line
      matched_line = match_line_to_html(line, raw_markup)
      output += matched_line[:html]
        
      output = append_font_info(output, @fonts[@matches[1].to_sym], {})
      {:plain => matched_line[:plain], :html => output}
    end
    
    def match_line_to_html(input, raw_markup)
      part_char = ""
      output = ""
      offset = 0
      rewrite = ""
      line = input.dup.strip
      
      (0..line.length-1).each do |i|
        char = line[i]
        
        part_char = @matches[3][i+offset]
        
        if part_char.nil?
          if offset+i == @matches[3].length and @part+1 < @parts.length
            @part+=1
            @matches = @parts[@part].match(/<font label='([^']+)' size='([^']+)'>([^<]*)/)
            output = append_font_info(output, @font, @matches[1].to_sym)
            offset = (i * -1)
            part_char = @matches[3][i+offset]
          end
        end
        
        while part_char != char
          if char == " " and output =~ /^\d\.\s+(<(?:i|b)>)*$/
            temp_char = line[i+1]
            if part_char == temp_char
              if $1
                markup = $1
                output = "#{output.gsub(markup, "")} #{markup}"
              else
                output = "#{output} "
              end
              offset -=1
              break
            end
          elsif part_char == " " and char =~ /[a-zA-Z]/
            if output.strip.length > 0
              rewrite = "#{line[0..i-1]} #{line[i..-1]}"
              output = "#{output}#{part_char}"
              offset +=1
              part_char = @matches[3][i+offset]
              break
            else
              offset += 1
              if @part+1 < @parts.length and i+offset > @matches[3].length-1
                @part+=1
                @matches = @parts[@part].match(/<font label='([^']+)' size='([^']+)'>([^<]*)/)
                output = append_font_info(output, @font, @matches[1].to_sym)
                offset = (i * -1)
              end
              part_char = @matches[3][i+offset]
            end
          else
            offset +=1
            part_char = @matches[3][i+offset]
            if offset+i == @matches[3].length and @part+1 < @parts.length
              @part+=1
              @matches = @parts[@part].match(/<font label='([^']+)' size='([^']+)'>([^<]*)/)
              output = append_font_info(output, @font, @matches[1].to_sym)
              offset = (i * -1)
              part_char = @matches[3][i+offset]
            end
          end
        end
        if part_char == char
          output = "#{output}#{part_char}"
        end
      end
      
      unless rewrite.empty?
        if input =~ /^(\s*).*(\s*)$/
          rewrite = "#{$1}#{rewrite}#{$2}"
        end
        input = rewrite
      end
      {:plain => input, :html => output}
    end
    
    def append_font_info(string, old_font, font_symbol)
      unless string == ""
        string = "#{string}</b>" if old_font[:bold]
        string = "#{string}</i>" if old_font[:italic]
      end
      
      unless font_symbol == {}
        @font = @fonts[font_symbol]
        string = "#{string}<i>" if @font[:italic]
        string = "#{string}<b>" if @font[:bold]
      end
      string
    end
    
    def enumerate_fonts(page)
      font_objs = build_fonts(page.fonts)
      fonts = {}
      page.fonts.each do |label, font|
        bold = false
        italic = false
        base = font[:BaseFont].to_s.split(",")
        font_style = base.length > 1 ? base.pop : ""
        family = base.first.split("+").last
        if font_style.include?("Bold") or family.include?("Bold")
          bold = true
        end
        if font_style.include?("Italic") or family.include?("Italic")
          italic = true
        end
        
        obj = font_objs[label]
        
        fonts[label] = {:family => family, :bold => bold, :italic => italic, :pdf_object => font_objs[label] }
      end
      fonts
    end
    
    #stolen from PDF::Reader::PageState
    def build_fonts(raw_fonts)
      wrapped_fonts = raw_fonts.map { |label, font|
        [label, PDF::Reader::Font.new(@objects, @objects.deref(font))]
      }
      
      ::Hash[wrapped_fonts]
    end
end

class TextReceiver
  def initialize(page_fonts)
    @fonts = page_fonts
    @lines = []
    @text = []
    @last_line = 9999.9
    @font = {}
    @footer = []
  end
  
  def content
    @lines + [" "] + @footer
  end
  
  def set_text_matrix_and_text_line_matrix(_, _, _, _, _, y_axis)
    if y_axis != @last_line
      if @last_line < 50.00
        @footer << dedup_font_tags(@text.join(""))
        @text = []
      else
        process_linebreak(y_axis)
      end
    end
    @last_line = y_axis
  end
  
  def move_text_position(_, y_axis)
    process_linebreak(y_axis)
  end
  
  def move_text_position_and_set_leading(_, y_axis)
    process_linebreak(y_axis)
  end
  
  def move_to_start_of_next_line
    process_linebreak(-1)
  end
  
  def set_text_font_and_size(label, size)
    @font = {:label => label, :size => size}
  end
   
  def show_text(text)
    utf8 = @fonts[@font[:label]][:pdf_object].to_utf8(text)
    @text << "<font label='#{@font[:label]}' size='#{@font[:size]}'>#{utf8}</font>"
  end
  
  def show_text_with_positioning(array)
    text = array.select{|i| i.is_a?(String)}.join("")
    utf8 = @fonts[@font[:label]][:pdf_object].to_utf8(text)
    @text << "<font label='#{@font[:label]}' size='#{@font[:size]}'>#{utf8}</font>"
  end
  
  private
    def process_linebreak(y_axis)
      if y_axis != 0
        unless @text.empty?
          @lines << dedup_font_tags(@text.join(""))
          @text = []
        end
      end
    end
    
    def dedup_font_tags(input)
      output = ""
      last_font = ""
      bits = []
      
      bits = input.split("</font>")
      
      bits.each_with_index do |bit, pos|
        matches = bit.match(/(<font label='(.+)' size='(.+)'>)(.*)/)
        font = {:label => "#{matches[2]}", :size => "#{matches[3]}"}
        if pos == bits.length-1 and matches[4] == ""
          #the last piece is empty, ignore it
          last_font = font
          output = "#{output}"
        elsif last_font == ""
          #first one, act differently
          output = bit
          last_font = font
        else
          if last_font == font
            output = "#{output}#{matches[4]}"
          else
            output = "#{output}</font>#{bit}"
            last_font = font
          end
        end
      end
      if output == ""
        ""
      else
        output = "#{output.strip}</font>"
      end
      
      if output =~ /<font[^>]*>(.*)<\/font>/ and $1.empty?
        output = ""
      end
      output
    end
end