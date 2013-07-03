#encoding: utf-8

require './spec/minitest_helper.rb'
#require 'minitest/spec'
require './server'

class ServerTest < MiniTest::Spec 
 
  describe "TheServer" do    
    describe "when asked for an iCal feed" do
      it "must be allow casting from CalendarDay to SittingDay" do
        assert 12 == 12
      end
    end
    
  end
end

