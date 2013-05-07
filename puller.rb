require "open-uri"
require "./parser"
require "pp"

Dir.glob('./PDFs/*.pdf') do |pdf|
  @parser = Parser.new(pdf)
  @parser.process
  pp @parser.output
end


#target_link = ""
#forthcoming_business_page = Nokogiri::HTML(open("http://www.lordswhips.org.uk/display/templatedisplay1.asp?sectionid=7"))
#target_link = forthcoming_business_page.css('a').reverse.select {|link| link['href'].include?("http://www.lordswhips.org.uk/documents/") }
#io     = open(URI::encode(target_link[0]['href']))
