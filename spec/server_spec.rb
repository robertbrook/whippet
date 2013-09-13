#encoding: utf-8

require './spec/rspec_helper.rb'
require 'rack/test'
require './server'

def app
  Sinatra::Application
end
 
describe "TheServer" do
  context "when asked for an iCal feed at /cal" do
    it "should generate output"
    
    it "should generate output with MIME type text/calendar"
  end
  
  context "when asked for an iCal feed at /cal?ics" do
    it "should generate output"
    
    it "should generate output with MIME type text/calendar"
  end
  
  context "when asked for the URL /2013/03/27" do
    it "should have a link to the PDF"
      
    it "should have a link to the Lords calendar"
  end
    
  context "when running a search for 'Regulations'" do  
    it "should return these results"
  end
    
  context "when running a search for 'Lord McNally'" do
    it "should return these results"
  end
end
