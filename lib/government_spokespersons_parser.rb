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
  ############# from here ##########
  def scrape
    response = RestClient.get(@page)
    doc = Nokogiri::HTML(response.body)
    paras = doc.xpath("//div[@id='mainmiddle']/p")
    paras.each do |para|
      if para.text.strip =~ /.*The House will sit/
        @sitting_days = extract_sitting_days(para.text)
        break
      end
    end
    return @sitting_days
  end
  
  private
  
  def extract_sitting_days(text)
    text.match(/Fridays in (\d+):/)
    year = $1
    
    excerpt_start = text.index("in #{year}") + "in #{year}".length + 1
    excerpt_end = text.index(".")-1
    day_text = text[excerpt_start..excerpt_end]
    days = []
    day_text.split(",").each do |day|
      days << "#{day.strip} #{year}"
    end
    days
  end
end