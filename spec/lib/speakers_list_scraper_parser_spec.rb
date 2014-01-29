# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/speakers_list_parser'

describe SpeakersListParser do

  before(:all) do
    @parser = SpeakersListParser.new()
  end
  
  describe "when creating a new instance" do 
  
    it "should return a SpeakersListParser" do
      @parser.should be_an_instance_of(SpeakersListParser)
    end
    
    it "should know which page to look at" do
      @parser.page.should eq "http://www.lordswhips.org.uk/speakers-lists"
    end
    
    it "should set speakers_list to an empty array" do
      @parser.speakers_lists.should eq []
    end
    
  end
  
  describe "when attempting to scrape a Speakers List page" do
    
    it "should time out after failing to get a reponse after three seconds"
    
    
  end
  
  describe "after successfully scraping a Speakers List page" do
  
    it "should return an array of target URLs" 
    
    it "should follow each target URL"
    
    it "should parse from each target URL"
  
  end
  
end