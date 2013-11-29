require 'rest-client'
require 'nokogiri'
require 'active_record'
require "./models/government_spokesperson"

class GovernmentSpokespersonsParser
  attr_reader :government_spokespersons, :page
  
  def initialize
    @page = "http://www.lordswhips.org.uk/government-spokespersons"
    @government_spokespersons = []
  end
  
  def parse
    government_spokespersons = scrape()
    government_spokespersons.each do |government_spokesperson|
#       GovernmentSpokesperson.find_or_create_by(:name => government_spokesperson)
      p government_spokesperson
    end
  end

  def scrape
    page = Nokogiri::HTML(RestClient.get(@page)) 
    page.css("div.normalcontent > p").children.each do |line|
        person = {}

        if line.text.length > 2
          
          if line.name == "strong"
            remit = line.text.strip
          end
          
          possible_role_and_name = line.text.strip.split(':')
          if (possible_role_and_name.length > 1)
            person['remit'] = remit
            person['role'] = possible_role_and_name[0]
            person['name'] = possible_role_and_name[1].strip
          else
            person['remit'] = remit
            person['role'] = ''
            person['name'] = possible_role_and_name[0]
          end
          
          p person
          
        end
        
    end
       
  end
  
  
end