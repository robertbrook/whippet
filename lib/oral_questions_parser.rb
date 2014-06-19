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

  def parse
    oral_questions = scrape()
    oral_questions['questions'].each do |oral_question|
      OralQuestion.where(:complete => oral_question[0][:complete], :date_string => oral_question[0][:date_string]).first_or_create
    end
  end

  def scrape
    @oral_questions = {}
    response = RestClient.get(@page)

    @oral_questions['title'] = ""
    @oral_questions['date_sections'] = []
    @oral_questions['questions'] = []

    response.body.each_line do |line|

      case line
      when /Week beginning (.*)<\/strong>/
          @oral_questions['title'] = $1

      when /<p class="txt666 txtbold">(.*)<\/p>/
          @oral_questions['date_sections'] << $1

      when /<p>(.*)<\/p>/
          if $1.include? "to ask Her Majesty"
            @oral_questions['questions'] << [:date_string => @oral_questions['date_sections'][-1], :complete => $1]
          end

      else
          ""
      end
      
    end

    # puts @oral_questions.to_yaml
    @oral_questions

  end

  def complete
    "hello"
  end

end
       