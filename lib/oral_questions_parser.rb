require 'rest-client'
require 'nokogiri'
require 'date'
require "active_record"
require "./models/oral_question.rb"

class OralQuestionsParser
  attr_reader :page, :oral_questions, :title, :date_sections
  
  def initialize(page = "http://www.lordswhips.org.uk/oral-questions")
    @page = page
    @oral_questions = []
    @title = ""
    @date_sections = []
  end

  def parse
    oral_questions = scrape()
    oral_questions['questions'].each do |oral_question|
      OralQuestion.where(:complete => oral_question[0][:complete], :date_string => oral_question[0][:date_string]).first_or_create
      puts '.'
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

      when /.*to ask Her Majesty.*/
            @oral_questions['questions'] << [:date_string => @oral_questions['date_sections'][-1], :complete => $~[0]]
            # p /(?<=<p>).*to ask Her Majesty.*(?=<\/p>)/.match(line)
      else
          ""
      end
      
    end

    # puts @oral_questions.to_yaml
    @oral_questions

  end

end
       