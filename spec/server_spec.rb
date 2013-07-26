#encoding: utf-8

require './spec/minitest_helper.rb'
require './server'

class ServerTest < MiniTest::Spec 

include Rack::Test::Methods

  def app
    Sinatra::Application
  end
 
  describe "TheServer" do   
   
    describe "when asked for an iCal feed at /cal" do
      
      it "must generate output"
      
      it "must generate output with MIME type text/calendar"

    end
    
     describe "when asked for an iCal feed at /cal?ics" do
      
      it "must generate output"
      
      it "must generate output with MIME type text/calendar"
      
     end   
     
      describe "when asked for the URL /2013/03/27" do
      
        it "should have a link to the PDF"
        
        it "should have a link to the Lords calendar"
      
      end
      
      describe "when running a search for 'Regulations'" do
		it "should return these results"      
      end
      
      describe "when running a search for 'Lord McNally'" do
		it "should return these results"      
      end
    
  end
  
end

