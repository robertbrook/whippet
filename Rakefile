require 'bundler'
Bundler.setup

require 'rspec/core/rake_task'

namespace :spec do
  desc "Run tests with SimpleCov"
  RSpec::Core::RakeTask.new(:cov) do |t|
    ENV["COVERAGE"] = "1"
  end
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec


desc "Parse PDFs in data directory"
task :puller do |t|
  report_env()
  require "./lib/parser"
  
  Dir.glob('./data/*.pdf') do |pdf|
    @parser = Parser.new(pdf)
    @parser.process
    p pdf
  end
end

desc "import a single pdf file"
task :import_pdf_file do
  report_env()
  require "./lib/parser"
  
  input_file = ENV['pdf']
  if input_file
    parser = Parser.new(input_file)
    parser.process
  else
    p 'USAGE: rake import_pdf_file pdf=data/FB-TEST.pdf'
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

def report_env
  if ENV["MONGOHQ_DEV_URI"]
    p "running in production..."
  else
    if ENV["RACK_ENV"]
      p "running in #{ENV["RACK_ENV"]}..."
    else
      p "defaulting to development..."
    end
  end
end