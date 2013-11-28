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
    page.css("div.normalcontent > p").children.each do |thing|
      case thing
        when Nokogiri::XML::Text
          puts thing.text
        when Nokogiri::XML::Element
          if thing.name == 'strong'
            thing.children.each do |elem|
              puts elem.text
            end
          else 
            puts thing.name if thing.name != 'br'
          end
      end 
      
    end
       
#     
#     

    # paras.each do |para|
#       if para.text.strip =~ /.*The House will sit/
#         @sitting_days = extract_sitting_days(para.text)
#         break
#       end
#     end
#     return @government_spokespersons
  end
  
  
end