# encoding: utf-8

ENV['RACK_ENV'] = 'test'

require './spec/rspec_helper.rb'
require './server'

def app
  Sinatra::Application
end
 
describe "The server" do
  
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
  
  context "when asked for /index.txt" do
    it "should not give a blank response" do
       get "/index.txt"
       last_response.body.should_not eq ""
    end
    
    
    it "should generate output with MIME type text/plain" do
      get "/index.txt"      
      last_response.header['Content-Type'].should include 'text/plain'
    end
  end
  
  context "when asked for /editor" do
    it "should not give a blank response" do
       get "/editor"
       last_response.body.should_not eq ""
    end
  end
  
  context "when asked for /edit-mockup" do
    it "should not give a blank response" do
       get "/edit-mockup"
       last_response.body.should_not eq ""
    end
  end
  
  context "when asked for the URL /2013-03-27" do
    it "should have a link to 'FB 2013 03 27 r.pdf'" do
      pending("requires populated route for URL")
      get "/2013-03-27"
      last_response.body.should include 'PDF LINK'
    end
        
    it "should have a link to the Lords calendar" do 
      pending("requires view for date page in HTML")
      get "/2013-03-27"
    end
  end
    
  context "when running a search for 'Regulations'" do  
    it "should return these results" do 
      pending("requires search function and results view")
      get "/search?q=Regulations"
    end
  end
  
  context "when running a search with one space" do  
    it "should return no results" do 
      pending "separating out search code"
      get "/search?q=+"
      last_response.body.should include '<small>No results found</small>'
    end
  end
  
  context "when running a search with four spaces" do  
    it "should return no results" do 
      pending "separating out search code"
      get "/search?q=++++"
      last_response.body.should include '<small>sorry: I need something to search for</small>'
    end
  end
    
  context "when running a search for 'Lord McNally'" do
    it "should return these results" do 
      pending("requires search function and results view")
      get "/search?q=Lord%20McNally"

    end
    
  end
end
