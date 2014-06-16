require 'rest-client'
require 'nokogiri'
require 'date'

require "active_record"
require "./models/oral_question.rb"

class OralQuestionsDocument < Nokogiri::XML::SAX::Document
  def xmldecl(version, encoding, standalone)
  end
  def start_document
  end
  def end_document
  end
  def start_element(name, attrs = [])
    puts "#{name} started with attrs #{attrs.inspect}"
  end
  def end_element(name)
  end
  def start_element_namespace(name, attrs = [], prefix = nil, uri = nil, ns = [])
  end
  def end_element_namespace(name, prefix = nil, uri = nil)
  end
  def characters(string)
  end
  def comment(string)
  end
  def warning(string)
  end
  def error(string)
  end
  def cdata_block(string)
  end
end

class OralQuestionsParser
  attr_reader :page, :oral_questions, :title, :date_sections
  
  def initialize
    @page = "http://www.lordswhips.org.uk/oral-questions"
    @oral_questions = []
    @title = ""
    @date_sections = []
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
  
  # def scrape
  #   response = RestClient.get(@page)
  #   doc = Nokogiri::HTML(response.body)
  #   @title = doc.xpath("//td[@class='txt000']/strong")[0].text
  #   @date_sections = doc.xpath("//p[@class='txt666 txtbold']")
  #   paras = doc.xpath("//div[@class='questionpanel']/p")
  #   paras.each do |para|
  #     puts para.text
  #     puts
  #   end

  def scrape
    response = RestClient.get(@page)
    parser = Nokogiri::HTML::SAX::Parser.new(OralQuestionsDocument.new)
    parser.parse(response.body)
  end
       # reader = Nokogiri::XML::Reader

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