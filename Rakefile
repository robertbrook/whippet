require 'bundler'
Bundler.setup

require 'active_record'
require 'rspec/core/rake_task'

Dir["tasks/*.rake"].sort.each { |ext| load ext }

namespace :spec do
  task :prepare do
    ENV["RACK_ENV"] = "test"
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
  end
  
  desc "Run tests with SimpleCov"
  RSpec::Core::RakeTask.new(:cov) do |t|
    Rake::Task["spec:prepare"].invoke
    ENV["COVERAGE"] = "1"
  end
  
  desc "Run tests with SimpleCov and open generated index"
  RSpec::Core::RakeTask.new(:covopen) do |t|
    Rake::Task["spec:cov"].invoke
    `open ./coverage/index.html`
  end
  
  
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Parse PDFs in data directory"
task :puller => :environment do |t|
  report_env()
  require "./lib/pdf_parser"
  
  Dir.glob('./data/*.pdf') do |pdf|
    @parser = PdfParser.new(pdf)
    @parser.process
    p pdf
  end
end

desc "import a single pdf file"
task :import_pdf_file=> :environment  do
  report_env()
  require "./lib/pdf_parser"
  
  input_file = ENV['pdf']
  if input_file
    parser = PdfParser.new(input_file)
    parser.process
  else
    p 'USAGE: rake import_pdf_file pdf=data/FB-TEST.pdf'
  end
end

desc "import recess dates from web"
task :import_recess_dates => :environment do
  require "./lib/recess_dates_parser"
  parser = RecessDatesParser.new
  parser.parse
end

desc "import Sitting Friday dates from web"
task :import_sitting_fridays => :environment do
  require "./lib/sitting_fridays_parser"
  parser = SittingFridaysParser.new
  parser.parse
end

desc "import Government Spokespersons from web"
task :import_government_spokespersons => :environment do
  require "./lib/government_spokespersons_parser"
  parser = GovernmentSpokespersonsParser.new
  parser.parse
end

desc "Show target URL"
task :target do
  require "open-uri"
  require "nokogiri"

  forthcoming_business_page = Nokogiri::HTML(open("http://www.lordswhips.org.uk/fb"))
  target_link = forthcoming_business_page.xpath("//a[contains(@href,'download.axd?')]")
  p 'http://www.lordswhips.org.uk' + target_link[0]['href']
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