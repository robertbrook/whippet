#encoding: utf-8

ENV['RACK_ENV'] = 'test'

require './spec/rspec_helper.rb'
require 'rack/test'
require './server'

def app
  Sinatra::Application
end
 
describe "TheServer" do
  
  context "when asked for /cal" do
    it "should not give a blank response" do
      get "/cal"
      last_response.should_not eq ""
    end
    
    it "should give an HTTP OK" do
      get "/cal"
      last_response.should be_ok
    end
    
    it "should generate output with MIME type text/plain" do
      get "/cal"      
      last_response.header['Content-Type'].should include 'text/plain'
    end
  end
  
  context "when asked for /cal?ics" do
    it "should not give a blank response" do
      get "/cal?ics"
      last_response.should_not eq ""
    end
    
    it "should generate output with MIME type text/calendar" do
      get "/cal?ics"      
      last_response.header['Content-Type'].should include 'text/calendar'
    end
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
    
    it "should return one result only"
  end
end
