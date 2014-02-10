# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/speakers_list_parser'

describe SpeakersListParser do

  before(:all) do
    @parser = SpeakersListParser.new()
  end
  
  describe "when making a new Speakers List parser" do 
  
    it "should be a Speakers List parser" do
      @parser.should be_an_instance_of(SpeakersListParser)
    end
    
    it "should look at the Speakers List URL" do
      @parser.page.should eq "http://www.lordswhips.org.uk/speakers-lists"
    end
    
    it "should start with an empty list of Speakers Lists" do
      @parser.speakers_lists.should eq []
    end
    
  end
  
  describe "when attempting to scrape a Speakers List page" do
    
    it "should time out after failing to get a reponse after three seconds" do 
      pending "writing some actual code"  
    end
    
  end
  
  describe "after successfully scraping a Speakers List page" do
  
    it "should return an array of target URLs" 
    
    it "should follow each target URL"
    
    it "should parse from each target URL"
  
  end
  
end