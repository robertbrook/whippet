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
      get "/2013-03-27"
      expect(last_response.body).to match(/href='pdf\/FB 2013 03 20 r\.pdf'/)
    end
        
    it "should have a link to the Lords calendar" do 
#       pending("requires view for date page in HTML")
      
      get "/2013-03-20"
      expect(last_response.body).to match(/href='http:\/\/services.parliament.uk\/calendar\/Lords\/#!\/calendar\/Lords\/MainChamber\/2013\/3\/20\/events\.html'/)
    end
  end
    
  context "when running a search for 'Regulations'" do  
    it "should return 'Draft Civil Legal Aid (Merits Criteria) (Amendment) Regulations 2013'" do 
      get "/search?q=Regulations"
      expect(last_response.body).to include('Draft Civil Legal Aid (Merits Criteria) (Amendment) Regulations 2013')
    end
  end
  
  context "when running a search with one space" do  
    it "should return no results" do 
      get "/search?q=+"
      expect(last_response.body).to include('<small>No results</small>')
    end
  end
  
  context "when running a search with four spaces" do  
    it "should return no results" do 
      get "/search?q=++++"
      expect(last_response.body).to include('<small>No results</small>')
    end
  end
    
  context "when running a search for 'Lord McNally'" do
    it "should return these 'Draft Legal Aid, Sentencing and Punishment of Offenders Act 2012 (Amendment of Schedule 1) Order 2013 – Motion to Regret – Lord Bach/Lord McNally'" do 
      get "/search?q=Lord%20McNally"
      expect(last_response.body).to include('Draft Legal Aid, Sentencing and Punishment of Offenders Act 2012 (Amendment of Schedule 1) Order 2013 – Motion to Regret – Lord Bach/Lord McNally')
    end
    
  end
end
