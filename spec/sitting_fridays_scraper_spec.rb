# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/sitting_fridays_scraper'

describe SittingFridaysScraper do
  before(:all) do
    @scraper = SittingFridaysScraper.new()
  end
  
  describe "when creating a new instance" do 
    it "should return a SittingFridaysScraper" do
      @scraper.should be_an_instance_of(SittingFridaysScraper)
    end
    
    it "should know which page to look at" do
      @scraper.page.should eq "http://www.lordswhips.org.uk/sitting-fridays"
    end
    
    it "should set sitting_days to an empty array" do
      @scraper.sitting_days.should eq []
    end
  end
  
  context "when asked to scrape a page" do
    describe "when finding the page has a list of dates in the first paragraph" do
      before(:each) do
        html = %Q|<div id="mainmiddle"><p>The House will sit on the following Fridays in 2013: 5 July, 19 July, 25 October, 
        8 November, 6 December.
        <br><br><br>
        Further sitting Fridays may be advertised in due course.<br>
        
        <strong style="margin: 0px; padding: 0px; border: 0px; color: rgb(51, 51, 51); line-height: 21px;">
        ANELAY OF ST JOHNS</strong><br style="color: rgb(51, 51, 51); line-height: 21px;">
        <span style="color: rgb(51, 51, 51); line-height: 21px;">9 May 2013</span></p></div>|
        
        @response = mock("Fake Response")
        @response.stubs(:body).returns(html)
        RestClient.expects(:get).returns(@response)
      end
      
      it "should return a list of dates in sitting_days" do
        @scraper.scrape()
        @scraper.sitting_days.should eq (
          ["5 July 2013", "19 July 2013", "25 October 2013", "8 November 2013", "6 December 2013"])
      end
    end
    
    describe "when finding the page has a list of dates in the second paragraph" do
      before(:each) do
        html = %Q|<div id="mainmiddle"><p>spurious text</p><p>The House will sit on the following Fridays in 2013: 5 July, 19 July, 25 October.
        <br><br><br>
        Further sitting Fridays may be advertised in due course.<br></div>|
        
        @response = mock("Fake Response")
        @response.stubs(:body).returns(html)
        RestClient.expects(:get).returns(@response)
      end
      
      it "should return a list of dates in sitting_days" do
        @scraper.scrape()
        @scraper.sitting_days.should eq (
          ["5 July 2013", "19 July 2013", "25 October 2013"])
      end
    end
  end
end