#encoding: utf-8

require "pdf/reader"

module PDF
  class Reader
    
    class PageTextMarkupReceiver < PageTextReceiver
      
      def page=(page)
        super(page)
        @last_font = nil
        @last_tag_end = ""
        @lasty = 0.0
        @footer = []
        @text = []
      end
      
      def markup
        %Q|#{fix_markup(@text.join(""))}#{@footer.join("")}|
      end
      
      
      
      private
      
      def fix_markup(input)
        stack = []
        lines = input.split("\n")
        
        last_line = lines.pop
        while last_line.strip.empty?
          stack << last_line
          last_line = lines.pop
        end
        if last_line.strip =~ /(<b>)?(<i>)?(.*)/
          is_bold = !($1.nil?)
          is_italic = !($2.nil?)
          content = $3
          
          unless content.empty?
            if is_italic
              last_line = "#{last_line}</i>"
            end
            if is_bold
              last_line = "#{last_line}</b>"
            end
          else
            last_line = ""
          end
          lines << last_line
        end
        stack.reverse!
        while !stack.empty?
          lines << stack.pop
        end
        lines.join("\n")
      end
      
      def dedup_markup_tags(input)
        output = ""
        last_tag = ""
        bits = []
        
        bits = input.split(/<\/(?:b|i)>/)
        
        bits.each_with_index do |bit, pos|
          matches = bit.match(/([^<]*)(?:<(b|i)>)?(.*)/)
          pre = matches[1].nil? ? "" : matches[1]
          tag = matches[2].nil? ? "" : matches[2]
          content = matches[3]
          
          if pos == 0
            output = bit
            last_tag = tag
          else
            if last_tag == tag
              if pre.empty?
                output = "#{output}#{content}"
              else
                output = "#{output}</#{tag}>#{pre}<#{tag}>#{content}"
              end
            elsif last_tag == ""
              output = "#{output}<#{tag}>#{content}"
              last_tag = tag
            else
              if tag == ""
                output = "#{output}</#{last_tag}>#{content}"
              else
                output = "#{output}</#{last_tag}>#{pre}<#{tag}>#{content}"
              end
              last_tag = tag
            end
          end
        end
        if output == ""
          output = ""
        else
          output = "#{output.strip}</#{last_tag}>"
        end
        
        return output
      end
      
      def internal_show_text(string)
        if @state.current_font.nil?
          raise PDF::Reader::MalformedPDFError, "current font is invalid"
        end
        glyphs = @state.current_font.unpack(string)
        text = ""
        glyphs.each_with_index do |glyph_code, index|
          # paint the current glyph
          newx, newy = @state.trm_transform(0,0)
          utf8_chars = @state.current_font.to_utf8(glyph_code)
          
          # apply to glyph displacment for the current glyph so the next
          # glyph will appear in the correct position
          glyph_width = @state.current_font.glyph_width(glyph_code) / 1000.0
          th = 1
          scaled_glyph_width = glyph_width * @state.font_size * th
          run = TextRun.new(newx, newy, scaled_glyph_width, @state.font_size, utf8_chars)
          @characters << run
          @state.process_glyph_displacement(glyph_width, 0, utf8_chars == SPACE)  
          
          
          crlf = ""
          if @state.current_font == @last_font
            if newy < 50
              @footer << run.to_s
            else
              if newy < @lasty
                crlf  = "\n"
              end
              @text << "#{crlf}#{run.to_s}"
            end
          else
            if newy < @lasty
              crlf  = "\n"
            end
            if @state.current_font.font_descriptor.font_weight > 400
              if @state.current_font.font_descriptor.italic_angle != 0
                @text << "#{@last_tag_end}#{crlf}<b><i>#{run.to_s}"
                @last_tag_end = "</i></b>"
              else
                @text << "#{@last_tag_end}#{crlf}<b>#{run.to_s}"
                @last_tag_end = "</b>"
              end
            else
              if @state.current_font.font_descriptor.italic_angle != 0
                @text << "#{@last_tag_end}#{crlf}<i>#{run.to_s}"
                @last_tag_end = "</i>"
              else
                if newy < 50
                  @footer << "#{@last_tag_end}#{run.to_s}"
                else
                  @text << "#{@last_tag_end}#{crlf}#{run.to_s}"
                end
                @last_tag_end = ""
              end
            end
          end
          @last_font = @state.current_font
          @lasty = newy
        end
      end
    end
  end
end