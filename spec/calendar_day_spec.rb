#encoding: utf-8

require './spec/minitest_helper.rb'
require './models/calendar_day'

class CalendarDayTest < MiniTest::Spec  
  describe "CalendarDay" do    
    describe "in general" do
      it "must be allow casting from CalendarDay to SittingDay" do
        day = CalendarDay.new(:note => "test")
        sitting_day = day.becomes(SittingDay)
        sitting_day.must_be_kind_of SittingDay
        sitting_day.note.must_equal "test"
      end
      
      it "must return false for has_time_blocks? if not a SittingDay" do
        ns = NonSittingDay.new
        ns.has_time_blocks?.must_equal false
      end
      
      it "must return false for has_time_blocks? if a SittingDay has no time_blocks" do
        sit = SittingDay.new
        sit.has_time_blocks?.must_equal false
      end
      
      it "must return true for has_time_blocks? if a SittingDay has 1 or more time_blocks" do
        sit = SittingDay.new
        sit.time_blocks = [TimeBlock.new]
        sit.has_time_blocks?.must_equal true
      end
      
      it "must be allow casting from CalendarDay to NonSittingDay" do
        day = CalendarDay.new(:note => "test2")
        sitting_day = day.becomes(NonSittingDay)
        sitting_day.must_be_kind_of NonSittingDay
        sitting_day.note.must_equal "test2"
      end
      
      it "must throw an error when asked to diff with an object not derived from CalendarDay" do
        day = SittingDay.new
        compare_with_string = lambda { day.diff("test") }
        compare_with_string.must_raise RuntimeError
        error = compare_with_string.call rescue $!
        error.message.must_equal("Unable to compare SittingDay to String")
      end
    end
  end
end