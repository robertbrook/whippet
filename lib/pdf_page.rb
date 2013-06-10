require 'pdf/reader'

class PdfPage
  attr_reader :fonts, :lines
  
  def initialize(page)
    @fonts = enumerate_fonts(page)
    @markup_lines = walk_page(page)
    @lines = reconcile_lines(page)
  end
  
  private
    def walk_page(page)
      receiver = TextReceiver.new
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
          lines << {:plain => line, :html => line_to_html(line, markup)}
          offset +=1
        end
      end
      lines
    end
    
    def strip_high_ascii(input)
      ec = Encoding::Converter.new("ascii", "utf-8", :invalid => :replace, :replace => "")
      output = ec.convert(input)
      output.gsub!(/[\u0080-\u00ff]/,"")
      output.gsub(/\u0000/, "") #remove any stray nulls
    end
    
    def line_to_html(line, raw_markup)
      output = ""
      raw_markup = strip_high_ascii(raw_markup)
      line = line.strip
      parts = raw_markup.split("</font>")
      part = 0
      part_char = ""
      offset = 0
      @font = {}
      
      @matches = parts[part].match(/<font label='([^']+)' size='([^']+)'>([^<]*)/)
      output = append_font_info(output, {}, @matches[1].to_sym)
      #iterate over all the characters in the original line
      (0..line.length-1).each do |i|
        char = line[i..i]
        #check (until fixed) that we're not going to read past the end
        # of the current chunk of the raw_markup string
        part_char = @matches[3][i+offset..i+offset]
        while part_char != char
          offset +=1
          part_char = @matches[3][i+offset..i+offset]
          break if offset > @matches[3].length
        end  
        if part+1 < parts.length and i+offset > @matches[3].length-1
          part += 1
          @matches = parts[part].match(/<font label='([^']+)' size='([^']+)'>([^<]*)/)
          output = append_font_info(output, @font, @matches[1].to_sym)
          offset = i * -1
        end
        part_char = @matches[3][i+offset..i+offset]
        output = "#{output}#{char}"
      end
      append_font_info(output, @fonts[@matches[1].to_sym], {})
    end
    
    def append_font_info(string, old_font, font_symbol)
      unless string == ""
        string = "#{string}</i>" if old_font[:italic]
        string = "#{string}</b>" if old_font[:bold]
      end
      
      unless font_symbol == {}
        @font = @fonts[font_symbol]
        string = "#{string}<i>" if @font[:italic]
        string = "#{string}<b>" if @font[:bold]
      end
      string
    end
    
    def enumerate_fonts(page)
      fonts = {}
      page.fonts.each do |label, font|
        bold = false
        italic = false
        base = font[:BaseFont].to_s.split(",")
        if base.length > 1
          font_style = base.pop
        else
          font_style = ""
        end
        family = base.first.split("+").last
        bold = true if font_style.include?("Bold")
        italic = true if font_style.include?("Italic")
        
        fonts[label] = {:family => family, :bold => bold, :italic => italic}
      end
      fonts
    end
end

class TextReceiver
  attr_reader :content
  
  def initialize(debug=false)
    @content = []
    @text = []
    @last_line = 9999.9
    @font = {}
    @debug = debug
  end
  
  def set_text_matrix_and_text_line_matrix(_,_,_,_,_,y_axis)
    p "* #{y_axis}" if @debug
    if y_axis != @last_line
      line = dedup_font_tags(@text.join(""))
      @content << line.strip
      @text = []
      p "new line" if @debug
    end
    @last_line = y_axis
  end
  
  def set_text_font_and_size(label, size)
    @font = {:label => label, :size => size}
    p "#{label}, #{size}" if @debug
  end
  
  def show_text_with_positioning(array)
    # make use of the show text method we already have
    # assuming we don't care about positioning right now and just want the text
    text = array.select{|i| i.is_a?(String)}.join("")
    @text << "<font label='#{@font[:label]}' size='#{@font[:size]}'>#{text}</font>"
    p text if @debug
  end
  
  private
    def dedup_font_tags(input)
      output = ""
      last_font = ""
      bits = []
      
      bits = input.split("</font>")
      
      bits.each_with_index do |bit, pos|
        matches = bit.match(/(<font label='(.+)' size='(.+)'>)(.*)/)
        font = {:label => "#{matches[2]}", :size => "#{matches[3]}"}
        if pos == bits.length-1 and matches[4] != ""
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
    end
end