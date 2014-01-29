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
end