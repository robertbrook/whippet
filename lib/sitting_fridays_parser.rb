require 'rest-client'
require 'nokogiri'
require 'active_record'
require "./models/sitting_friday"


class SittingFridaysParser
  attr_reader :sitting_days, :page
  
  def initialize
    @page = "http://www.lordswhips.org.uk/sitting-fridays"
    @sitting_days = []
  end
  
  def parse
    sitting_days = scrape()
    sitting_days.each do |day|
      SittingFriday.find_or_create_by(:date => day)
    end
  end
  
  def scrape
    response = RestClient.get(@page)
    doc = Nokogiri::HTML(response.body)
    paras = doc.xpath("//div[@id='mainmiddle']//p")
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
    days = []
    p text
    if text.match(/Fridays in (\d+):/)
      year = $1

      excerpt_start = text.index("in #{year}") + "in #{year}".length + 1
      excerpt_end = text.index(".")-1
      day_text = text[excerpt_start..excerpt_end]
    
      day_text.split(",").each do |day|
        days << "#{day.strip!} #{year}"
      end
    else
      year = Time.now.year
      
      excerpt_start = text.index("Fridays:") + "Fridays:".length
      excerpt_end = text.index(".")-1
      day_text = text[excerpt_start..excerpt_end]
    
      day_text.split(",").each do |day|
        days << "#{day.strip!} #{year}"
      end
      
    end

    days
  end
end