require 'rest-client'
require 'nokogiri'
require 'active_record'
require './models/government_spokesperson'
require 'pp'

class GovernmentSpokespersonsParser
  attr_reader :government_spokespersons, :page
  
  def initialize
    @page = "http://www.lordswhips.org.uk/government-spokespersons"
    @local_test_file = './data/spokespersons.html'
    @government_spokespersons = []
  end
  
  def parse
     government_spokespersons = scrape()
    # government_spokespersons.each do |government_spokesperson|
#        GovernmentSpokesperson.find_or_create_by(:name => government_spokesperson)
#     end
  end

  def scrape
    if File.exist?(@local_test_file)
      page = Nokogiri::HTML(File.open(@local_test_file))
    else
      page = Nokogiri::HTML(RestClient.get(@page))
    end
    page.css("div.normalcontent > p").children.each do |line|
#       pp line

      if line.name == 'strong'
        section = line.children.text
        p section
      end      
      
      if section
        p 'in section: ' + section
      else
        p 'not in a section: ' + line.text
      end
      
    end
       
  end
  
  
end