# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/government_spokespersons_parser'

describe GovernmentSpokespersonsParser do
  before(:all) do
    @parser = GovernmentSpokespersonsParser.new()
  end
  
  describe "when creating a new instance" do 
    it "should return a GovernmentSpokespersonsParser" do
      @parser.should be_an_instance_of(GovernmentSpokespersonsParser)
    end
    
    it "should look for the URL 'http://www.lordswhips.org.uk/government-spokespersons'" do
      @parser.page.should eq "http://www.lordswhips.org.uk/government-spokespersons"
    end
    
    it "should set government_spokespersons to an empty array" do
      @parser.government_spokespersons.should eq []
    end
  end
  
  context "when asked to scrape a page" do
    describe "when finding the page" do
      before(:each) do
#         html = File.open('./data/spokespersons.html').read
#         @response = mock("Fake Response")
#         @response.stubs(:body).returns(html)
#         RestClient.expects(:get).returns(@response)
# not sure why this coughs
      end
      
      it "should return a list of government spokespersons in government_spokespersons" do 
        pending "working parser"
        @parser.scrape()
        @parser.government_spokespersons.should eq (["24 January 2014", "7 February 2014"])
      end
      
      it "should return a list of sections in government_spokespersons" do 
        pending "working parser"
        @parser.scrape()
        @parser.government_sections.should eq (["24 January 2014", "7 February 2014"])
      end
      
    end
    end
#     describe "when finding the page has a list of dates in the second paragraph" do
#       before(:each) do
#         html = %Q|<div id="mainmiddle"><p>spurious text</p><p>The House will sit on the following Fridays in 2013: 5 July, 19 July, 25 October.
#         <br><br><br>
#         Further sitting Fridays may be advertised in due course.<br></div>|
#         
#         @response = mock("Fake Response")
#         @response.stubs(:body).returns(html)
#         RestClient.expects(:get).returns(@response)
#       end
#       
#       it "should return a list of dates in sitting_days" do
#         @parser.scrape()
#         @parser.sitting_days.should eq (
#           ["5 July 2013", "19 July 2013", "25 October 2013"])
#       end
#     end
#   end
  
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