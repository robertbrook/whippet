require "pdf/reader"
require "nokogiri"

class Parser

  #prepare to ingest a single pdf
  def initialize(target_pdf)

    @pdf = PDF::Reader.new(target_pdf)
    @mytext = ""
    @business = {:dates => []}
    @last_line_was_blank = false
    @in_item = false
    @current_date = ""
  end

  def pages
    @pdf.pages
  end


  def process(debug=false)
    #concat all the page content into a single block of text
    @pdf.pages.each do |page|
      @mytext << "\n#{page.text}"
    end

    #loop over all the lines
    @mytext.lines.each do |line|
      case line

      #the end of the useful, the start of the notes section, we can stop now
      when /Information/
        p "ok, ignoring the rest of this" if debug
        break

        #a new day
      when /\b([A-Z]{2,}[DAY] \d.+)/
        p "new day detected, starting a new section: #{line}" if debug
        @last_line_was_blank = false
        @current_date = $1
        @in_item = false
        @business[:dates] << {:date => @current_date, :times => [], :note => ""}
      
      #a new time 
      when /^\b([A-Z])/
        p "new time detected, starting a new sub-section: #{line}" if debug
        @last_line_was_blank = false
        @in_item = false
        target = @business[:dates].select { |date|  date[:date] == @current_date }
        target.last[:times] << {:time => line.strip, :items => []}
      
      #a page number
      when /^\s*(\d+)\n/
        page_number = $1
        p "** end of page #{page_number} **" if debug

        #a numbered item
      when /^(\d)/
        p "new business item, hello: #{line}" if debug
        @last_line_was_blank = false
        @in_item = true
        # first line of item
        target = @business[:dates].select { |date|  date[:date] == @current_date }
        target.last[:times].last[:items] << {:item => line.strip}
      
      #a blank line
      when /^\n$/
        if @last_line_was_blank and @in_item
          p "A blank following a blank line, resetting the itemflag" if debug
          @in_item = false
        end
        @last_line_was_blank = true

        #whole line in square brackets
      when /^\s*\[.*\]\s*$/
        p "Meh, no need to process these #{line}" if debug
        @last_line_was_blank = false

        #all the other things
      else
        if @in_item
          @last_line_was_blank = false
          p "...item continuation line..." if debug
          #last line was a business item, treat this as a continuation
          target = @business[:dates].select { |date|  date[:date] == @current_date }
          last_item = target[0][:times].last[:items].pop
          last_line = "#{last_item[:item]} #{line.strip}"
          target.last[:times].last[:items] << {:item => last_line}

          p "item text replaced with: #{last_line}" if debug
        else
          #the last line wasn't blank and we're not in item space - a note!
          if line =~ /^\s+\b[A-Z][a-z]/ and @last_line_was_blank == false
            target = @business[:dates].select { |date|  date[:date] == @current_date }
            unless target.last[:times].empty?
              p "notes about the time: #{line}" if debug
              target.last[:times].last[:note] = line.strip
            else
              p "notes about the day: #{line}" if debug
              target.last[:note] = line.strip
            end
          else
            @last_line_was_blank = false
            p "Unhandled text: #{line}" if debug
          end
        end
      end
    end
  end

  def output
    @business
  end
end
