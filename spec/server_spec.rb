#encoding: utf-8

require './spec/minitest_helper.rb'
require './server'

class ServerTest < MiniTest::Spec 
 
  describe "TheServer" do    
    describe "when asked for an iCal feed at /cal" do
      it "must generate output" do
        skip "works locally, not on heroku"
      end
      
      
    end
     describe "when asked for an iCal feed at /cal?ics" do
      it "must generate output" do
        skip "works locally, not on heroku"
      end
      
      
    end   
  end
end

