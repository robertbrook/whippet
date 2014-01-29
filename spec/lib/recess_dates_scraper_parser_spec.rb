# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/recess_dates_parser'

describe RecessDatesParser do
  before(:all) do
    @parser = RecessDatesParser.new()
    @recesses = [
      {:name => "Summer",
       :start_date => "Wednesday 31 July 2013",
       :finish_date => "Monday 7 October 2013"},
      {:name => "Autumn long weekend",
       :start_date => "Wednesday 13 November 2013",
       :finish_date => "Sunday 17 November 2013"},
      {:name => "Christmas",
       :start_date => "Thursday 19 December 2013",
       :finish_date => "Monday 6 January 2014"}
    ]
  end
  
  describe "when creating a new instance" do 
    it "should return a RecessDatesParser" do
      @parser.should be_an_instance_of(RecessDatesParser)
    end
    
    it "should know which page to look at" do
      @parser.page.should eq "http://www.lordswhips.org.uk/recess-dates"
    end
  end
  
  context "when asked to scrape a page" do
    before(:each) do
      html = %Q|
      <h1>House of Lords Recess Dates</h1>
      <div id="mainmiddle">
      <div class="normalcontent">
        <p>filler!</p>
        <p>
          Subject to the progress of business, the House will adjourn for the following periods in 2013-14:
          <br>
          <br>
          <strong>2013</strong>
          <br>
          <em>Summer</em><br>
          
          Wednesday 31 July to Monday 7 October inclusive<br>
        </p>
        <br>
        <p>
          <em>Autumn long weekend</em>
          <br>
          
          Wednesday 13 November to Sunday 17 November inclusive<br>
          <br>
        </p>
        <p>
          <em>Christmas</em>
          <br>
          Thursday 19 December to Monday 6 January 2014 inclusive
          <br>
          <br>
          <br>
          <strong>ANELAY OF ST JOHNS</strong>
          <br>
          7 March 2013</p>
        </div>
      </div>|
      
      @response = mock("Fake Response")
      @response.stubs(:body).returns(html)
      RestClient.expects(:get).returns(@response)
    end
    
    it "should return a list of recess hashes comprising name, start date and finish date" do
      result = @parser.scrape()
      result.should eq @recesses
    end
  end
  
  context "when asked to parse a page" do
    before(:each) do
      @parser.expects(:scrape).returns(@recesses)
      @recess = mock("Recess")
      @recess.stubs(:save)
    end
    
    it "should store each recess in the database" do
      Recess.expects(:find_or_create_by).with(:name => "Summer", :year => "2013").returns(@recess)
      @recess.expects(:start_date=).with("Wednesday 31 July 2013")
      @recess.expects(:finish_date=).with("Monday 7 October 2013")
      
      Recess.expects(:find_or_create_by).with(:name => "Autumn long weekend", :year => "2013").returns(@recess)
      @recess.expects(:start_date=).with("Wednesday 13 November 2013")
      @recess.expects(:finish_date=).with("Sunday 17 November 2013")
      
      Recess.expects(:find_or_create_by).with(:name => "Christmas", :year => "2013").returns(@recess)
      @recess.expects(:start_date=).with("Thursday 19 December 2013")
      @recess.expects(:finish_date=).with("Monday 6 January 2014")
      
      @parser.parse
    end
  end
end