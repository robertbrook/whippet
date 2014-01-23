# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/speakers_list_parser'

describe SpeakersListParser do
  describe "when creating a new instance" do 
    it "should return a SpeakersListParser" do
      @parser.should be_an_instance_of(SpeakersListParser)
      p @parser
      p "ok"
    end
    	
    end
end