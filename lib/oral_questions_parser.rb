require 'rest-client'
require 'nokogiri'
require 'date'
require "active_record"
require "./models/oral_question.rb"


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
    @oral_questions = {}
    response = RestClient.get(@page)

    @oral_questions['title'] = ""
    @oral_questions['dates'] = []
    @oral_questions['questions'] = []
    response.body.each_line do |line|

      case line
      when /Week beginning (.*)<\/strong>/
          @oral_questions['title'] = $1
          # @oral_questions['state'] = $1

      when /<p class="txt666 txtbold">(.*)<\/p>/
          @oral_questions['dates'] << $1
          # @oral_questions['state'] = $1

      when /<p>(.*)<\/p>/
          puts $1
          @oral_questions['questions'] << [@oral_questions['dates'][-1], $1]
          # @oral_questions['state'] = $1

      else
          ""
      end
      
    end

    puts @oral_questions.to_yaml

  end

end
       