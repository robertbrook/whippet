# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/oral_questions_parser'



describe OralQuestionsParser do
  before(:all) do
    @parser = OralQuestionsParser.new()
  end
  
  describe "when creating a new instance" do 
    it "should return a OralQuestionsParser" do
      expect(@parser).to be_an_instance_of(OralQuestionsParser)
    end
    
    it "should look for the URL 'http://www.lordswhips.org.uk/oral-questions'" do
      expect(@parser.page).to eq "http://www.lordswhips.org.uk/oral-questions"
    end
    
    it "should set oral_questions to an empty array" do
      expect(@parser.oral_questions).to eq []
    end
  end
  
  context "when asked to scrape the oral questions page for the week beginning Monday 23rd June 2014" do

    describe "when finding the page" do
      before(:each) do
        html = File.open('./data/Week-beginning-Monday-23-June-2014.html').read
        @response = mock("Fake Response")
        @response.stubs(:body).returns(html)
        RestClient.expects(:get).returns(@response)
      end
      
      it "should return a title of 'Monday 23 June 2014'" do 
        @parser.scrape()
        expect(@parser.oral_questions['title']).to eq("Monday 23 June 2014")
      end

      it "should return a list of date sections with 4 items" do 
        @parser.scrape()
        expect(@parser.oral_questions['date_sections'].length).to eq(4)
      end

      xit "should return a list of 13 questions" do 
        @parser.scrape()
        expect(@parser.oral_questions['questions'].length).to eq(13)
      end

      it "should return 4 questions when asked for questions with a date string of 'Monday 23 June 2014'" do 
        @parser.scrape()
        expect(@parser.oral_questions['questions'].select {|question| question[0][:date_string] == 'Monday 23 June 2014'} .length).to eq(4)
      end

      it "should return 3 questions when asked for questions with a date string of 'Tuesday 24 June 2014'" do 
        @parser.scrape()
        expect(@parser.oral_questions['questions'].select {|question| question[0][:date_string] == 'Tuesday 24 June 2014'} .length).to eq(3)
      end

      it "should return 3 questions when asked for questions with a date string of 'Wednesday 25 June 2014'" do 
        @parser.scrape()
        expect(@parser.oral_questions['questions'].select {|question| question[0][:date_string] == 'Wednesday 25 June 2014'} .length).to eq(3)
      end

      it "should return nothing when asked for the fifth date section'" do 
        @parser.scrape()
        expect(@parser.oral_questions['date_sections'][4]).to eq(nil)
      end

      xit "should return 3 questions when asked for questions with a date string of 'Thursday 26 June 2014'" do 
        @parser.scrape()
        expect(@parser.oral_questions['questions'].select {|question| question[0][:date_string] == 'Thursday 26 June 2014'}.length).to eq(3)
      end

      it "should return the complete first question with a date string of 'Thursday 26 June 2014'" do 
        @parser.scrape()
        thursday_questions = @parser.oral_questions['questions'].select {|question| question[0][:date_string] == 'Thursday 26 June 2014'}
        my_question = OralQuestion.where(:complete => "Baroness Masham of Ilton to ask Her Majesty’s Government what steps they will take to help to remove barriers to access to secondary care for symptomatic patients so they are identified and can start treatment earlier. Earl Howe (Department of Health).", :date_string => "Thursday 26 June 2014").first_or_initialize
        expect(my_question.complete).to eq("Baroness Masham of Ilton to ask Her Majesty’s Government what steps they will take to help to remove barriers to access to secondary care for symptomatic patients so they are identified and can start treatment earlier. Earl Howe (Department of Health).")
      end

      it "should return the questioner of the first question with a date string of 'Thursday 26 June 2014' as 'Baroness Masham of Ilton'" do 
        @parser.scrape()
        thursday_questions = @parser.oral_questions['questions'].select {|question| question[0][:date_string] == 'Thursday 26 June 2014'}
        my_question = OralQuestion.where(:complete => "Baroness Masham of Ilton to ask Her Majesty’s Government what steps they will take to help to remove barriers to access to secondary care for symptomatic patients so they are identified and can start treatment earlier. Earl Howe (Department of Health).", :date_string => "Thursday 26 June 2014").first_or_initialize
        expect(my_question.questioner).to eq("Baroness Masham of Ilton")
      end

      it "should return the text of the first question with a date string of 'Thursday 26 June 2014'" do  
        @parser.scrape()
        thursday_questions = @parser.oral_questions['questions'].select {|question| question[0][:date_string] == 'Thursday 26 June 2014'}
        my_question = OralQuestion.where(:complete => "Baroness Masham of Ilton to ask Her Majesty’s Government what steps they will take to help to remove barriers to access to secondary care for symptomatic patients so they are identified and can start treatment earlier. Earl Howe (Department of Health).", :date_string => "Thursday 26 June 2014").first_or_initialize
        expect(my_question.text).to eq("what steps they will take to help to remove barriers to access to secondary care for symptomatic patients so they are identified and can start treatment earlier.")
      end
      
      it "should return the answerer of the first question with a date string of 'Thursday 26 June 2014' as 'Earl Howe'" do 
        @parser.scrape()
        thursday_questions = @parser.oral_questions['questions'].select {|question| question[0][:date_string] == 'Thursday 26 June 2014'}
        my_question = OralQuestion.where(:complete => "Baroness Masham of Ilton to ask Her Majesty’s Government what steps they will take to help to remove barriers to access to secondary care for symptomatic patients so they are identified and can start treatment earlier. Earl Howe (Department of Health).", :date_string => "Thursday 26 June 2014").first_or_initialize
        expect(my_question.answerer).to eq("Earl Howe")
      end

      it "should return the department of the first question with a date string of 'Thursday 26 June 2014' as 'Department of Health'" do 
        @parser.scrape()
        thursday_questions = @parser.oral_questions['questions'].select {|question| question[0][:date_string] == 'Thursday 26 June 2014'}
        my_question = OralQuestion.where(:complete => "Baroness Masham of Ilton to ask Her Majesty’s Government what steps they will take to help to remove barriers to access to secondary care for symptomatic patients so they are identified and can start treatment earlier. Earl Howe (Department of Health).", :date_string => "Thursday 26 June 2014").first_or_initialize
        expect(my_question.department).to eq("Department of Health")
      end

      # it "should return a questioner of 'Lord Lexden' for the first question" do
      #   @parser.scrape()
      #   p @parser.oral_questions['questions'][0].inspect
      #   my_question = OralQuestion.where(:complete => "Baroness Masham of Ilton to ask Her Majesty’s Government what steps they will take to help to remove barriers to access to secondary care for symptomatic patients so they are identified and can start treatment earlier. Earl Howe (Department of Health).", :date_string => "Thursday 26 June 2014").first_or_initialize

      #   # expect(@parser.oral_questions['questions'][0].questioner).to eq "Lord Lexden"
      # end

      # xit "should return an answerer of 'Minister to be confirmed'" do
      #   @parser.scrape()
      #   expect(@parser.oral_questions).first.answerer.to eq "Minister to be confirmed"
      # end

      # xit "should return a department of 'Department for Education'" do
      #   @parser.scrape()
      #   expect(@parser.oral_questions).first.department.to eq "Department for Education"
      # end

      # it "should return a list of oral questions in oral_questions including the section 'Leader of the House of Lords and Chancellor of the Duchy of Lancaster'" do 
      #   @parser.scrape()
      #   expect(@parser.government_sections).to include("Leader of the House of Lords and Chancellor of the Duchy of Lancaster")
      # end
      
      # it "should return a list of sections in government_spokespersons" do 
      #   @parser.scrape()
      #   expect(@parser.government_sections).to be_an(Array)
      # end
      
    end
    

  end
  
#   context "when asked to parse the data" do
#     before(:each) do
#       @parser.expects(:scrape).returns(["5 July 2013", "25 October 2013", "8 November 2013"])
#     end
#     
#     it "should write each found date to the database" do
#       SittingFriday.expects(:find_or_create_by).with(:date => "5 July 2013")
#       SittingFriday.expects(:find_or_create_by).with(:date => "25 October 2013")
#       SittingFriday.expects(:find_or_create_by).with(:date => "8 November 2013")
#       @parser.parse
#     end
#   end
end