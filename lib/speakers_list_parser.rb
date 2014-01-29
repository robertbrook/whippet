require 'rest-client'
require 'nokogiri'
require 'active_record'
require "./models/speakers_list"

class SpeakersListParser
   attr_reader :speakers_lists, :page
  
  def initialize
    @page = "http://www.lordswhips.org.uk/speakers-lists"
    @speakers_lists = []
  end
   
  def parse
    speakers_lists = scrape()
    # speakers_lists.each do |day|
#       SittingFriday.find_or_create_by(:date => day)
#     end
  end
   
  def scrape
    response = RestClient.get(@page)
    doc = Nokogiri::HTML(response.body)
    paras = doc.xpath("//a[@class='smbtnprint toright']/")
    paras.each do |para|
      p para
      # if para.text.strip =~ /.*The House will sit/
#         @sitting_days = extract_sitting_days(para.text)
#         break
#       end
    end
    return @speakers_lists
  end
#   
#   private
#   
#   def extract_sitting_days(text)
#     text.match(/Fridays in (\d+):/)
#     year = $1
#     
#     excerpt_start = text.index("in #{year}") + "in #{year}".length + 1
#     excerpt_end = text.index(".")-1
#     day_text = text[excerpt_start..excerpt_end]
#     days = []
#     day_text.split(",").each do |day|
#       days << "#{day.strip} #{year}"
#     end
#     days
#   end
end