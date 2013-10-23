require 'rest-client'
require 'nokogiri'

class RecessDatesScraper
  attr_reader :page
  
  def initialize
    @page = "http://www.lordswhips.org.uk/recess-dates"
    @recesses = []
  end
  
  def scrape
    response = RestClient.get(@page)
    doc = Nokogiri::HTML(response.body)
    paras = doc.xpath("//div[@id='mainmiddle']/p")
    paras.each do |para|
      if para.text.strip =~ /the following dates:/
        @recesses = extract_recess_days(para.inner_html)
        break
      end
    end
    @recesses
  end
  
  private
  
  def extract_recess_days(html)
    lines = html.split("<br>")
    
    recesses = []
    recess = {}
    lines[1..lines.count-1].each do |line|
      case line.strip
      when ""
        #blank, ignore
      when /^Note/
        #work out how to extract data from here?
        break
      when /^<strong>/
        #the sign-off, stop! (there might not be a note)
        break
      else
        if recess.empty?
          recess = {:name => line.strip}
        else
          dates = line.split(" to ")
          recess[:start_date] = dates[0].strip
          recess[:finish_date] = dates[1].gsub("inclusive", "").strip
          recesses << recess
          recess = {}
        end
      end
    end
    recesses
  end
  
end