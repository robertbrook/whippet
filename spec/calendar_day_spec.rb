#encoding: utf-8

require './spec/minitest_helper.rb'
require './models/calendar_day'

class CalendarDayTest < MiniTest::Spec  
  describe "CalendarDay" do
    describe "in general" do
      it "must allow casting from CalendarDay to SittingDay" do
        day = CalendarDay.new(:note => "test")
        sitting_day = day.becomes(SittingDay)
        sitting_day.must_be_kind_of SittingDay
        sitting_day.note.must_equal "test"
      end
      
      it "must allow casting from CalendarDay to NonSittingDay" do
        day = CalendarDay.new(:note => "test2")
        sitting_day = day.becomes(NonSittingDay)
        sitting_day.must_be_kind_of NonSittingDay
        sitting_day.note.must_equal "test2"
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
    end
    
    describe "when asked for diffs" do
      it "must throw an error when asked to diff with an object not derived from CalendarDay" do
        day = SittingDay.new
        compare_with_string = lambda { day.diff("test") }
        compare_with_string.must_raise RuntimeError
        error = compare_with_string.call rescue $!
        error.message.must_equal("Unable to compare SittingDay to String")
      end
      
      it "must return an empty Hash if there is no significant difference between the 2 objects" do
        day = SittingDay.new
        day2 = SittingDay.new
        (day2 == day).must_equal false
        day.diff(day2).must_be_empty
      end
      
      it "must return diffs/alt values for each of the simple attributes when they change" do
        current_day = SittingDay.new(:accepted => true)
        previous_day = NonSittingDay.new(:note => "House not expected to sit", :accepted => false, :is_provisional => false)
        diff = current_day.diff(previous_day)
        
        diff[:note].to_s.must_equal "[[[\"+\", 0, \"H\"], [\"+\", 1, \"o\"], [\"+\", 2, \"u\"], [\"+\", 3, \"s\"], [\"+\", 4, \"e\"], [\"+\", 5, \" \"], [\"+\", 6, \"n\"], [\"+\", 7, \"o\"], [\"+\", 8, \"t\"], [\"+\", 9, \" \"], [\"+\", 10, \"e\"], [\"+\", 11, \"x\"], [\"+\", 12, \"p\"], [\"+\", 13, \"e\"], [\"+\", 14, \"c\"], [\"+\", 15, \"t\"], [\"+\", 16, \"e\"], [\"+\", 17, \"d\"], [\"+\", 18, \" \"], [\"+\", 19, \"t\"], [\"+\", 20, \"o\"], [\"+\", 21, \" \"], [\"+\", 22, \"s\"], [\"+\", 23, \"i\"], [\"+\", 24, \"t\"]]]"
        diff[:accepted].must_equal false
        diff[:is_provisional].must_equal false
        diff[:_type].must_equal "NonSittingDay"
      end
      
      it "must return a list of changes when a time block is removed" do
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am")
        tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm")
        current_day = SittingDay.new()
        longer_day = SittingDay.new()
        current_day.time_blocks = [tb1]
        longer_day.time_blocks = [tb1, tb2]
        
        # We're comparing the current (new, incoming) position with the old one
        # therefore the diff therefore represents the changes that would be applied on rollback.
        # Which means it's reversed, which looks a little weird *breaks out painkillers*
        diff = current_day.diff(longer_day)
        diff[:time_block_headings].to_s.must_equal "[[[\"+\", 1, \"Business in Grand Committee at 3.45pm\"]]]"
      end
      
      it "must return a list of changes and file info when a new time block is added" do
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am")
        tb2 = TimeBlock.new(
          :title => "Business in Grand Committee at 3.45pm",
          pdf_info: {
            filename: "FB-TEST.pdf",page: 1,
            line: 29,
            last_edited: "2013-03-28T10:23:03Z"
          })
        shorter_day = SittingDay.new()
        current_day = SittingDay.new()
        shorter_day.time_blocks = [tb1]
        current_day.time_blocks = [tb1, tb2]
        
        diff = current_day.diff(shorter_day)
        diff[:time_block_headings].to_s.must_equal "[[[\"-\", 1, \"Business in Grand Committee at 3.45pm\"]]]"
      end
      
      it "must be able to tell the difference between a removed and a repositioned block"
      
      it "must record all the contents and metadata of a removed block"
      
      it "must record only the position change and origin data of a repositioned block if the contents have not changed"
      
      it "must see a time_block with a different time as an alteration to an existing block"
      #wait, does this actually happen? There's no example of it among our sample files
      
      it "must not return any extra data for an added block"
    end
  end
end