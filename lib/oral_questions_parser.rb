require 'rest-client'
require 'nokogiri'
require 'date'

require "active_record"
require "./models/recess.rb"

class OralQuestionsParser
  attr_reader :page, :oral_questions
  
  def initialize
    @page = "http://www.lordswhips.org.uk/oral-questions"
    @oral_questions = []
  end
  
#   def parse
#     recesses = scrape()
#     recesses.each do |recess|
#       name = recess[:name]
#       year = recess[:start_date][-4..-1]
#       rec = Recess.find_or_create_by(:name => name, :year => year)
#       rec.start_date = recess[:start_date]
#       rec.finish_date = recess[:finish_date]
#       rec.save
#     end
#   end
  
#   def scrape
#     @recesses = []
#     response = RestClient.get(@page)
#     doc = Nokogiri::HTML(response.body)
#     paras = doc.xpath("//div[@id='mainmiddle']/div/p")
#     year = ""
#     name = ""
#     paras.each do |para|
#       para.children.each do |node|
#         case node.name
#         when "strong"
#           if node.text.strip =~ /^(\d{4})$/
#             year = $1
#           end
#         when "em"
#           name = node.text
#         when "text"
#           dates = extract_recess_days(node.text, year)
#           unless dates.empty?
#             @recesses << {:name => name, :start_date => dates[0], :finish_date => dates[1]}
#           end
#         end
#       end
#     end
#     @recesses
#   end
  
#   private
  
#   def extract_recess_days(text, year)
#     days = []
#     if text =~ /([A-Z][a-z]+day\s+\d+\s+[A-Z][a-z]+(?:\s+\d{4})?)\s+to\s+([A-Z][a-z]+day\s+\d+\s+[A-Z][a-z]+(?:\s+\d{4})?)/
#       days << append_year(year, $1)
#       days << append_year(year, $2)
#     end
#     days
#   end
  
#   def append_year(year, string)
#     unless string.strip =~ /\d{4}$/
#       string = "#{string} #{year}"
#     end
#     string
#   end
end