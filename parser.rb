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
        @dateflag = $1
        @itemflag = ""
        @business[:dates] << {:date => @dateflag, :times => [], :note => ""}
      
      #a new time 
      when /^([A-Z])/
        p "new time detected, starting a new sub-section: #{line}" if debug
        target = @business[:dates].select { |date|  date[:date] == @dateflag  }
        target[0][:times] << {:time => line.strip, :items => []}
      
      #a numbered item 
      when /^(\d)/
        p "new business item, hello: #{line}" if debug
        @itemflag = $1
        # puts "\t\t" + line
        # first line of item
        target = @business[:dates].select { |date|  date[:date] == @dateflag  }
        target[0][:times].last[:items] << {:item => line.strip}
        
      #a blank line
      when /^\n$/
        p
        #when /^[    ]/
      
      #all the other things
      else
        p "Undetected otherness: #{line}" if debug
        if @itemflag == ""
          # not picking up everything correctly yet
          target = @business[:dates].select { |date|  date[:date] == @dateflag  }
          target[0][:note] = line.strip
        else
          p
          #puts @itemflag.to_s + "\t\t" + line
        end
      end
    end
  end
  
  def output
    @business
  end
end
