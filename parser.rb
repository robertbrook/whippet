require "rubygems"
require "pdf/reader"
require "nokogiri"
require "open-uri"
require "pp"

# could loop over all possible dates?

target_link = ""
forthcoming_business_page = Nokogiri::HTML(open("http://www.lordswhips.org.uk/display/templatedisplay1.asp?sectionid=7"))
target_link = forthcoming_business_page.css('a').reverse.select {|link| link['href'].include?("http://www.lordswhips.org.uk/documents/") }

io     = open(URI::encode(target_link[0]['href']))
pdf = PDF::Reader.new(io)

#pdf = PDF::Reader.new("FB 2013 03 27 r.pdf")
mytext = ""
business = {:dates => []}

pdf.pages.each do |page|
  mytext << page.text
end

mytext.lines.each do |line|

  case line

  when /Information/
    break

  when /\b([A-Z]{2,}[DAY] \d.+)/
            @dateflag = $1
            @itemflag = ""
            business[:dates] << {:date => @dateflag, :times => []}

        when /^(\d)/
            @itemflag = $1
            # puts "\t\t" + line
            target = business[:dates].select { |date|  date[:date] == @dateflag  }
            pp target
            #puts "item parent: " + @itemflag

        when /^([A-Z])/
            target = business[:dates].select { |date|  date[:date] == @dateflag  }
            target[0][:times] << {:time => line.strip, :items => []}

        when /^\n$/
          p
    #when /^[    ]/
  when

    if @itemflag == ""
      puts "no attached item: " + line
    else
      puts @itemflag.to_s + "\t\t" + line
    end

  end
end

pp business

