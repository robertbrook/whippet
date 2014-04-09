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
    lines = doc.xpath("//div[@class='normalcontent']/p/*")
    
    lines.each do |line|
      @government_spokespersons << line.class
      # if para.text.strip =~ /.*The House will sit/
#         @government_spokespersons = extract_government_spokespersons(para.text)
#         break
#       end
    end
    return @government_spokespersons
  end
  
  private
  
  def extract_government_spokespersons(text)
    days = []
    
    if text.match(/Fridays in (\d+):/)
      year = $1

      excerpt_start = text.index("in #{year}") + "in #{year}".length + 1
      excerpt_end = text.index(".")-1
      spokesperson_text = text[excerpt_start..excerpt_end]
    
      spokesperson_text.split(",").each do |spokesperson|
        spokespersons << "#{spokesperson.strip} #{year}"
      end
    else
      year = Time.now.year
      spokespersons << "dummy spokesperson #{year}"
    end

    spokespersons
  end
  
end