require 'rest-client'
require 'nokogiri'
require 'active_record'
require './models/government_spokesperson'
require 'pp'

class GovernmentSpokespersonsParser
  attr_reader :government_spokespersons, :page
  
  def initialize
    @page = "http://www.lordswhips.org.uk/government-spokespersons"
    @government_spokespersons = []
  end
  
  def parse
     government_spokespersons = scrape()
    # government_spokespersons.each do |government_spokesperson|
#        GovernmentSpokesperson.find_or_create_by(:name => government_spokesperson)
#     end
  end

  def scrape

    page = Nokogiri::HTML(RestClient.get(@page))

    page.css("div.normalcontent > p").children.each do |line|
#       pp line

      if line.name == 'strong'
        @section = line.children.text
      end      
      
      if @section
        'in section: ' + @section
      else
        'not in a section: ' + line.text
      end
      
    end
       
  end
  
  
end