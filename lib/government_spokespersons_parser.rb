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
    @government_sections = []
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
    section_chunks = doc.xpath("//div[@class='normalcontent']/p").text.split("\r\n\r\n")
#     p lines.match(/^(\n)(.*)$/m)
    section_chunks.each do |section_chunk|
      bits = section_chunk.split("\r\n")
#       puts "\n\n" + bits[0] + " ARE " + bits[1..bits.size].join(" AND ")
      @government_sections << bits[0].gsub(/\W$/,"")
      # House of Lords Government Whips
#       @government_spokespersons << extract_government_spokespersons(elem)
    end
    return @government_spokespersons
  end
  
  def government_sections
    @government_sections = @government_sections - ["House of Lords Government Whips"]
    return @government_sections
  end
  
  private
  
  def extract_government_spokespersons(elem)
    spokespersons = []
#     
#     unless elem.name == "br"
#       spokespersons << elem
#     	
#     end
    spokespersons
  end
  
end