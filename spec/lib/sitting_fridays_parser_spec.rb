# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/sitting_fridays_parser'

describe SittingFridaysParser do
  before(:all) do
    @parser = SittingFridaysParser.new()
  end
  
  describe "when creating a new instance" do 
    it "should return a SittingFridaysParser" do
      @parser.should be_an_instance_of(SittingFridaysParser)
    end
    
    it "should know which page to look at" do
      @parser.page.should eq "http://www.lordswhips.org.uk/sitting-fridays"
    end
    
    it "should set sitting_days to an empty array" do
      @parser.sitting_days.should eq []
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
        result = @parser.scrape()
        @parser.sitting_days.should eq (
          ["5 July 2013", "19 July 2013", "25 October 2013", "8 November 2013", "6 December 2013"])
        result.should eq @parser.sitting_days
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
        @parser.scrape()
        @parser.sitting_days.should eq (
          ["5 July 2013", "19 July 2013", "25 October 2013"])
      end
    end
    
    describe "when finding the page has a list of dates with no year specified" do
      before(:each) do
        html = %Q|<div class="rightDotBorder">

                <div id="mainmiddle" class="Tgrayborder">
                    

<h1>Sitting Fridays</h1>

    <div class="normalcontent">
        <p>The House will sit on the following Fridays: &nbsp;24 January, 7 February.<br />
<br />
Further sitting Fridays may be advertised in due course.<br />
<br />
<strong style="margin: 0px; padding: 0px; border: 0px; color: rgb(51, 51, 51);">ANELAY OF ST JOHNS</strong><br style="color: rgb(51, 51, 51);" />
<span style="color: rgb(51, 51, 51);">15 January 2013</span></p>

    </div>
    <div class="clr20"></div>
    <div style="border-bottom: solid 1px #ccc;"></div>
    <div class="clr20"></div>



                </div>
                <!--end of mainright-->
            </div>
            <!--end of rightDotBorder-->|
        
        @response2 = mock("Next Fake Response")
        @response2.stubs(:body).returns(html)
        RestClient.expects(:get).returns(@response2)
      end
      
      it "should return a list of dates in sitting_days with the assumption that the year is the current year" do
        @parser.scrape()
        @parser.sitting_days.should eq (
          ["24 January 2014", "7 February 2014"])
      end
    end
  end
  
  context "when asked to parse the data" do
    before(:each) do
      @parser.expects(:scrape).returns(["5 July 2013", "25 October 2013", "8 November 2013"])
    end
    
    it "should write each found date to the database" do
      SittingFriday.expects(:find_or_create_by).with(:date => "5 July 2013")
      SittingFriday.expects(:find_or_create_by).with(:date => "25 October 2013")
      SittingFriday.expects(:find_or_create_by).with(:date => "8 November 2013")
      @parser.parse
    end
  end
end