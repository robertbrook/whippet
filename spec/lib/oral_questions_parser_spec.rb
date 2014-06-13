# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/oral_questions_parser'

describe OralQuestionsParser do
  before(:all) do
    @parser = OralQuestionsParser.new()
  end
  
  describe "when creating a new instance" do 
    it "should return a OralQuestionsParser" do
      @parser.should be_an_instance_of(OralQuestionsParser)
    end
    
    it "should look for the URL 'http://www.lordswhips.org.uk/oral-questions'" do
      expect(@parser.page).to eq "http://www.lordswhips.org.uk/oral-questions"
    end
    
    it "should set oral_questions to an empty array" do
      @parser.oral_questions.should eq []
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
      
      it "should return a title of 'Week beginning Monday 23 June 2014'" do 
        @parser.scrape()
        expect(@parser.title).to eq("Week beginning Monday 23 June 2014")
      end

      it "should return a list of date sections with 4 items" do 
        @parser.scrape()
        expect(@parser.date_sections.length).to eq(4)
      end

      
      
      # it "should return a list of oral questions in oral_questions including the section 'Leader of the House of Lords and Chancellor of the Duchy of Lancaster'" do 
      #   @parser.scrape()
      #   expect(@parser.government_sections).to include("Leader of the House of Lords and Chancellor of the Duchy of Lancaster")
      # end
      
      # it "should return a list of sections in government_spokespersons" do 
      #   @parser.scrape()
      #   expect(@parser.government_sections).to be_an(Array)
      # end
      
    end
    
    describe "and finding the first oral question on the page" do
      before(:each) do
        html = %Q|<p>Lord Lexden&nbsp;to ask Her Majesty’s Government what assessment they have made of the impact of independent schools on the British economy, in the light of the report&nbsp;<em>The impact of independent schools on the British economy</em>, published by the Independent Schools Council in April. <strong>Minister to be confirmed (Department for Education). </strong></p>|
        
        @response = mock("Fake Response")
        @response.stubs(:body).returns(html)
        RestClient.expects(:get).returns(@response)
      end
      
      xit "should return a questioner of 'Lord Lexden'" do
        @parser.scrape()
        expect(@parser.oral_questions).first.questioner.to eq "Lord Lexden"
      end

      xit "should return an answerer of 'Minister to be confirmed'" do
        @parser.scrape()
        expect(@parser.oral_questions).first.answerer.to eq "Minister to be confirmed"
      end

      xit "should return a department of 'Department for Education'" do
        @parser.scrape()
        expect(@parser.oral_questions).first.department.to eq "Department for Education"
      end


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