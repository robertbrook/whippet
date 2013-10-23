require 'rest-client'
require 'nokogiri'
require 'date'

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
    data_end = false
    
    recesses = []
    recess = {}
    lines[1..lines.count-1].each do |line|
      case line.strip
      when ""
        #blank, ignore
      when /^Note/
        #work out how to extract data from here?
      when /^<strong>/
        #the sign-off, stop! (there might not be a note)
        data_end = true
      else
        if data_end
          begin
            date = Date.parse(line.strip)
            year = date.year
            recesses = add_year_to_dates(recesses, year)
            break
          rescue
            #ah, not the line I was expecting
          end
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
    end
    recesses
  end
  
  def add_year_to_dates(items, year)
    items.each do |item|
      item[:start_date] = append_year(year, item[:start_date])
      item[:finish_date] = append_year(year, item[:finish_date])
    end
    items
  end
  
  def append_year(year, string)
    unless string =~ /\d{4}$/
      string = "#{string} #{year}"
    end
    string
  end
end