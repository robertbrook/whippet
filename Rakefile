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

end

desc "Show target URL"
task :target do
  require "open-uri"
  require "nokogiri"

  forthcoming_business_page = Nokogiri::HTML(open("http://www.lordswhips.org.uk/fb"))
  target_link = forthcoming_business_page.css('a').detect {|link| link['href'].class == String and  link['href'].include? 'www.lordswhips.org.uk/download.axd?id='}
  
  
  p URI::encode(target_link['href'])
#io     = open(URI::encode(target_link[0]['href']))
end

