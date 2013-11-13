# encoding: utf-8

ENV['RACK_ENV'] = 'test'

require './spec/rspec_helper.rb'
require 'rack/test'
require './server'

def app
  Sinatra::Application
end
 
describe "TheServer" do
  
  context "when asked for /index.ics" do
    it "should not give a blank response" do
      get "/index.ics"
      last_response.should_not eq ""
    end
    
    it "should generate output with MIME type text/calendar" do
      get "/index.ics"      
      last_response.header['Content-Type'].should include 'text/calendar'
    end
  end
  
  context "when asked for the URL /2013-03-27" do
    it "should have a link to the PDF" do
      pending("requires populated route for URL")
    end
        
    it "should have a link to the Lords calendar" do 
      pending("requires view for date page in HTML")
    end
  end
    
  context "when running a search for 'Regulations'" do  
    it "should return these results" do 
      pending("requires search function and results view")
    end
  end
    
  context "when running a search for 'Lord McNally'" do
    it "should return these results" do 
      pending("requires search function and results view")
    end
    
  end
end
