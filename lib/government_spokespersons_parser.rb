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
    government_spokespersons.each do |day|
      GovernmentSpokesperson.find_or_create_by(:date => day)
    end
  end

  def scrape
    response = RestClient.get(@page)
    doc = Nokogiri::HTML(response.body)
    lines = doc.xpath("//div[@class='normalcontent']/p").text
    puts lines
    # elems.each do |elem|
#       @government_spokespersons << extract_government_spokespersons(elem)
#     end
    
    return @government_spokespersons
  end
  
  private
  
  def extract_government_spokespersons(elem)
    spokespersons = []
    
    unless elem.name == "br"
      spokespersons << elem
    	
    end
    spokespersons
  end
  
end