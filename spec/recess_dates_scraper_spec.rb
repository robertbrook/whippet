# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/recess_dates_scraper'

describe RecessDatesScraper do
  before(:all) do
    @scraper = RecessDatesScraper.new()
  end
  
  describe "when creating a new instance" do 
    it "should return a RecessDatesScraper" do
      @scraper.should be_an_instance_of(RecessDatesScraper)
    end
    
    it "should know which page to look at" do
      @scraper.page.should eq "http://www.lordswhips.org.uk/recess-dates"
    end
  end
  
  context "when asked to scrape a page" do
    describe "when finding the page has a list of dates in the first paragraph" do
      before(:each) do
        html = %Q|<div id="mainmiddle"><p>Subject to the progress of business, the House will adjourn for the following dates:<br>
        <br>
        Summer<br>
        Wednesday 31 July to Monday 7 October inclusive<br>
        <br>
        Autumn long weekend<br>
        Wednesday 13 November to Sunday 17 November inclusive<br>
        <br>
        Christmas<br>
        Thursday 19 December to Monday 6 January 2014 inclusive<br>
        <br>
        Note: Subject to the progress of business, the House of Lords will sit for the same number of weeks as the House of Commons in 2013, but on different dates. It is not currently proposed that the House of Lords will sit in September 2013.<br>
        <br>
        <br>
        <strong>ANELAY OF ST JOHNS</strong><br>
        7 March 2013</p></div>|
        
        @response = mock("Fake Response")
        @response.stubs(:body).returns(html)
        RestClient.expects(:get).returns(@response)
      end
      
      it "should return a list of recess hashes comprising name, start date and finish date" do
        result = @scraper.scrape()
        result.should eq (
          [
            {:name => "Summer",
             :start_date => "Wednesday 31 July",
             :finish_date => "Monday 7 October"},
            {:name => "Autumn long weekend",
             :start_date => "Wednesday 13 November",
             :finish_date => "Sunday 17 November"},
            {:name => "Christmas",
             :start_date => "Thursday 19 December",
             :finish_date => "Monday 6 January 2014"}
          ])
      end
    end
    
    describe "when finding the page has a list of dates in the 2nd paragraph, with no Note" do
      before(:each) do
        html = %Q|<div id="mainmiddle"><p>filler!</p><p>Subject to the progress of business, the House will adjourn for the following dates:<br>
        <br>
        Summer<br>
        Wednesday 31 July to Monday 7 October inclusive<br>
        <br>
        Autumn long weekend<br>
        Wednesday 13 November to Sunday 17 November inclusive<br>
        <br>
        Christmas<br>
        Thursday 19 December to Monday 6 January 2014 inclusive<br>
        <br>
        <br>
        <br>
        <strong>ANELAY OF ST JOHNS</strong><br>
        7 March 2013</p></div>|
        
        @response = mock("Fake Response")
        @response.stubs(:body).returns(html)
        RestClient.expects(:get).returns(@response)
      end
      
      it "should return a list of recess hashes comprising name, start date and finish date" do
        result = @scraper.scrape()
        result.should eq (
          [
            {:name => "Summer",
             :start_date => "Wednesday 31 July",
             :finish_date => "Monday 7 October"},
            {:name => "Autumn long weekend",
             :start_date => "Wednesday 13 November",
             :finish_date => "Sunday 17 November"},
            {:name => "Christmas",
             :start_date => "Thursday 19 December",
             :finish_date => "Monday 6 January 2014"}
          ])
      end
    end
  end
end