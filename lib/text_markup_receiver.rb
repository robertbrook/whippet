#encoding: utf-8

module PDF
  class Reader
    
    class TextMarkupReceiver
      def initialize(page_fonts, mark_up_as_html=true)
        @fonts = page_fonts
        @font = {}
        @process_html = mark_up_as_html
        
        @body = []
        @footer = []
        @formatted_body = []
        @formatted_footer = []
        
        @current_section = ""
        
        @structure = []
        
        @text = []
        @lines = []
        @formatted_text = []
        @formatted_lines = []
      end
      
      def lines
        @body + [""] + @footer
      end
      
      def content
        @formatted_body + [""] + @formatted_footer
      end
      
      def begin_marked_content_with_pl(label, dict)
        if (dict.has_key?(:Subtype) and dict[:Subtype] == :Footer) \
             or dict[:Attached] == [:Bottom]
          @current_section = :footer
          @structure << "footer"
        else
          if @current_section.empty?
            @current_section = :body
          end
          @structure << label
        end
      end
      
      def end_marked_content
        closed = @structure.pop
        
        unless @text.empty?
          @lines << @text.join("")
          
          f_line = dedup_font_tags(@formatted_text.join(""))
          if @process_html
            @formatted_lines << line_to_html(f_line)
          else
            @formatted_lines << f_line
          end
          @text = []
          @formatted_text = []
        end
        
        case @current_section
        when :footer
          @footer += @lines
          @formatted_footer += @formatted_lines
          if closed == "footer"
            @current_section = :body
          end
        when :body
          @body += @lines
          @formatted_body += @formatted_lines
        end
        @lines = []
        @formatted_lines = []
      end
      
      def set_text_matrix_and_text_line_matrix(_, _, _, _, _, y_axis)
        if y_axis != @last_line
          process_linebreak(y_axis)
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
      
      def end_document
        unless @structure.empty?
          process_linebreak(-1)
        end
      end
      
      def append_line(_, y_axis)
        if y_axis < 0
          process_line_break(y_axis)
        else
          process_linebreak(-1)
        end
      end
      
      def set_text_font_and_size(label, size)
        @font = {:label => label, :size => size}
      end
      
      def show_text(text)
        utf8 = @fonts[@font[:label]][:pdf_object].to_utf8(text)
        @text << utf8
        @formatted_text << "<font label='#{@font[:label]}' size='#{@font[:size]}'>#{utf8}</font>"
      end
      
      def show_text_with_positioning(array)
        text = array.select{|i| i.is_a?(String)}.join("")
        utf8 = @fonts[@font[:label]][:pdf_object].to_utf8(text)
        @text << utf8
        @formatted_text << "<font label='#{@font[:label]}' size='#{@font[:size]}'>#{utf8}</font>"
      end
      
      
      private
        def process_linebreak(y_axis)
          if y_axis != 0
            if @text.empty?
              @lines << ""
              @formatted_lines << ""
            else
              @lines << @text.join("")
              
              f_line = dedup_font_tags(@formatted_text.join(""))
              if @process_html
                @formatted_lines << line_to_html(f_line)
              else
                @formatted_lines << f_line
              end
              @text = []
              @formatted_text = []
            end
          end
        end
        
        def dedup_font_tags(input)
          output = ""
          last_font = ""
          bits = []
          
          bits = input.split("</font>")
          
          bits.each_with_index do |bit, pos|
            matches = bit.match(/(<font label='(.+)' size='(.+(?:\.\d+)?)'>)(.*)/)
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
            output = ""
          else
            output = "#{output.strip}</font>"
          end
          
          if output =~ /<font[^>]*>(.*)<\/font>/ and $1.empty?
            output = ""
          end
          
          return output
        end
        
        def line_to_html(line)
          output = ""
          tagged_segments = line.split("</font>")
          tagged_segments.each do |segment|
            matches = segment.match /\<font label='(.*)' size='\d+(?:\.\d+)?'\>(.*)/
            if matches
              font_label = matches[1].to_sym
              text = matches[2]
              font = @fonts[font_label]
              if font[:italic] and font[:bold]
                unless text.empty?
                  output = "#{output}<b><i>#{text}</i></b>"
                end
              elsif font[:italic]
                unless text.empty?
                  output = "#{output}<i>#{text}</i>"
                end
              elsif font[:bold]
                unless text.empty?
                  output = "#{output}<b>#{text}</b>"
                end
              else
                output = "#{output}#{text}"
              end
            else
              output = "#{output}#{line.strip}"
            end
          end
          return output
        end
    end
  end
end