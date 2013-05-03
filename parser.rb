require "rubygems"
require "pdf/reader"
require "nokogiri"
require "open-uri"
require "pp"
require "yaml"

# could loop over all possible dates?

class Parser
  
  #prepare to ingest a single pdf
  def initialize(target_pdf)
    #target_link = ""
    #forthcoming_business_page = Nokogiri::HTML(open("http://www.lordswhips.org.uk/display/templatedisplay1.asp?sectionid=7"))
    #target_link = forthcoming_business_page.css('a').reverse.select {|link| link['href'].include?("http://www.lordswhips.org.uk/documents/") }
    
    #io     = open(URI::encode(target_link[0]['href']))
    #pdf = PDF::Reader.new(io)
    
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
      when /^([A-Z])/
        p "new time detected, starting a new sub-section: #{line}" if debug
        @last_line_was_blank = false
        @in_item = false
        target = @business[:dates].select { |date|  date[:date] == @current_date  }
        target[0][:times] << {:time => line.strip, :items => []}
      
      #a numbered item 
      when /^(\d)/
        p "new business item, hello: #{line}" if debug
        @last_line_was_blank = false
        @in_item = true
        # first line of item
        target = @business[:dates].select { |date|  date[:date] == @current_date  }
        target[0][:times].last[:items] << {:item => line.strip}
        
      #a blank line
      when /^\n$/
        if @last_line_was_blank
          p "A blank following a blank line, resetting the itemflag" if debug
          @in_item = false
        end
        @last_line_was_blank = true
      
      #whole line in square brackets
      when /^\s*\[.*\]\s*$/
        p "Notes!? #{line}" if debug
        @last_line_was_blank = false
      
      #all the other things
      else
        @last_line_was_blank = false
        p "Undetected otherness: #{line}" if debug
        if @in_item
          #last line was a business item, treat this as a continuation
          target = @business[:dates].select { |date|  date[:date] == @current_date }
          last_item = target[0][:times].last[:items].pop
          last_line = "#{last_item[:item]} #{line.strip}"
          target[0][:times].last[:items] << {:item => last_line}
          
          p "item text replaced with: #{last_line}" if debug
        end
      end
    end
  end
  
  def output
    @business
  end
end
