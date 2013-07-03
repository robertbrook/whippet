require 'bundler'
Bundler.setup

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

desc "Parse PDFs in data directory"
task :puller do |t|
  require "./lib/parser"

Dir.glob('./data/*.pdf') do |pdf|
  @parser = Parser.new(pdf)
  @parser.process
  p pdf
end



#require "open-uri"

#target_link = ""
#forthcoming_business_page = Nokogiri::HTML(open("http://www.lordswhips.org.uk/display/templatedisplay1.asp?sectionid=7"))
#target_link = forthcoming_business_page.css('a').reverse.select {|link| link['href'].include?("http://www.lordswhips.org.uk/documents/") }
#io     = open(URI::encode(target_link[0]['href']))

end

