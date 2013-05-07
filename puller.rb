require "open-uri"

# could loop over all possible dates?

#target_link = ""
#forthcoming_business_page = Nokogiri::HTML(open("http://www.lordswhips.org.uk/display/templatedisplay1.asp?sectionid=7"))
#target_link = forthcoming_business_page.css('a').reverse.select {|link| link['href'].include?("http://www.lordswhips.org.uk/documents/") }

#io     = open(URI::encode(target_link[0]['href']))
#pdf = PDF::Reader.new(io)