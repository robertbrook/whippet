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
      
      it "must not return a list of changes if the time blocks are the same" do
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am")
        tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am")
        day1 = SittingDay.new()
        day2 = SittingDay.new()
        day1.time_blocks = [tb1]
        day2.time_blocks = [tb2]
        day1.diff(day2).must_be_empty
      end
      
      describe "when a time block is added" do
        it "must return change_type of 'new' for the block" do
          tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am")
          tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm")
          current_day = SittingDay.new()
          shorter_day = SittingDay.new()
          shorter_day.time_blocks = [tb1]
          current_day.time_blocks = [tb1, tb2]
          
          diff = current_day.diff(shorter_day)
          
          block_changes = diff[:time_blocks]
          block_changes.first[:change_type].must_equal "new"
        end
        
        it "must return the title for the block" do
          tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am")
          tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm")
          current_day = SittingDay.new()
          shorter_day = SittingDay.new()
          shorter_day.time_blocks = [tb1]
          current_day.time_blocks = [tb1, tb2]
          
          diff = current_day.diff(shorter_day)
          
          block_changes = diff[:time_blocks]
          block_changes.must_be_instance_of Array
          block_changes.must_equal [{:change_type => "new", :title => "Business in Grand Committee at 3.45pm"}]
        end
      end
      
      describe "when a time block is deleted" do
        it "must return a change_type of 'deleted' for the block" do
          tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am")
          tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm",)
          tb2.position = 2
          
          longer_day = SittingDay.new()
          current_day = SittingDay.new()
          current_day.time_blocks = [tb1]
          longer_day.time_blocks = [tb1, tb2]
          
          diff = current_day.diff(longer_day)
          
          block_changes = diff[:time_blocks]
          block_changes.first[:change_type].must_equal "deleted"
        end
        
        it "must return all the details of the deleted block" do
          tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am")
          tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm")
          tb2.position = 2
          tb2.pdf_info = {
              filename: "FB-TEST.pdf",
              page: 1,
              line: 29,
              last_edited: "2013-03-28T10:23:03Z"
            }
          
          longer_day = SittingDay.new()
          current_day = SittingDay.new()
          current_day.time_blocks = [tb1]
          longer_day.time_blocks = [tb1, tb2]
          
          diff = current_day.diff(longer_day)
          
          block_changes = diff[:time_blocks]
          block_changes.must_equal [
            {:change_type => "deleted", 
             :title => "Business in Grand Committee at 3.45pm",
             :position => 2,
             :pdf_info=>{"filename"=>"FB-TEST.pdf", "page"=>1, "line"=>29, "last_edited"=>"2013-03-28T10:23:03Z"}}]
        end
        
        it "must return all the business_item data for removed time_blocks" do
          tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am")
          tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm")
          tb2.position = 2
          item = BusinessItem.new(:description => "Further business will be scheduled", :position => 1)
          tb2.business_items = [item]
          
          longer_day = SittingDay.new()
          current_day = SittingDay.new()
          current_day.time_blocks = [tb1]
          longer_day.time_blocks = [tb1, tb2]
          
          diff = current_day.diff(longer_day)
          
          block_change = diff[:time_blocks].first
          block_change[:change_type].must_equal "deleted"
          item_changes = block_change[:business_items]
          item_changes.must_be_instance_of Array
          item_changes.length.must_equal 1
          change = item_changes.first
          change[:change_type].must_equal "deleted"
          change[:description].must_equal "Further business will be scheduled"
          change[:position].must_equal 1
        end
      end
      
      describe "when a block is modified" do
        it "must return a change_type of 'modified' for the block" do
          tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1)
          tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 2)
          
          longer_day = SittingDay.new()
          current_day = SittingDay.new()
          current_day.time_blocks = [tb1]
          longer_day.time_blocks = [tb2]
          
          diff = current_day.diff(longer_day)
          
          block_changes = diff[:time_blocks]
          block_changes.first[:change_type].must_equal "modified"
        end
      end
      
      it "must record only the position change and origin data of a repositioned block if the contents have not changed"
    end
  end
end