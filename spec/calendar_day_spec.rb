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
      
      it "must return the original values for each of the simple attributes that have changed" do
        current_day = SittingDay.new(:accepted => true)
        previous_day = NonSittingDay.new(:note => "House not expected to sit", :accepted => false, :is_provisional => false)
        diff = current_day.diff(previous_day)
        
        diff[:note].must_equal "House not expected to sit"
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
        before do
          @tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1)
          @tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 2)
          @longer_day = SittingDay.new()
          @current_day = SittingDay.new()
        end
        
        it "must return a change_type of 'modified' for the block" do
          @current_day.time_blocks = [@tb1]
          @longer_day.time_blocks = [@tb2]
          
          diff = @current_day.diff(@longer_day)
          
          block_changes = diff[:time_blocks]
          block_changes.first[:change_type].must_equal "modified"
        end
        
        describe "when a business item has been added" do
          it "must return a change_type of 'new' for the item" do
            item = BusinessItem.new(:description => "1.  description goes here", :position => 1)
            @tb1.business_items = [item]
            @current_day.time_blocks = [@tb1]
            @longer_day.time_blocks = [@tb2]
            
            diff = @current_day.diff(@longer_day)
            item_changes = diff[:time_blocks].first[:business_items]
            item_changes.first[:change_type].must_equal "new"
          end
          
          it "must return the description for the item" do
            item = BusinessItem.new(:description => "1.  description goes here", :position => 1)
            @tb1.business_items = [item]
            @current_day.time_blocks = [@tb1]
            @longer_day.time_blocks = [@tb2]
            
            diff = @current_day.diff(@longer_day)
            
            item_changes = diff[:time_blocks].first[:business_items]
            item_changes.must_be_instance_of Array
            item_changes.must_equal [{:change_type => "new", :description => "1.  description goes here"}]
          end
        end
        
        describe "when a business item has been deleted" do
          it "must return a change_type of 'deleted' for the item" do
            item = BusinessItem.new(:description => "1.  description goes here", :position => 1)
            @tb1.business_items = [item]
            @current_day.time_blocks = [@tb2]
            @longer_day.time_blocks = [@tb1]
            
            diff = @current_day.diff(@longer_day)
            
            item_changes = diff[:time_blocks].first[:business_items]
            item_changes.first[:change_type].must_equal "deleted"
          end
          
          it "must return all the details of the original item" do
            item = BusinessItem.new(:description => "1.  description goes here", :position => 1, :pdf_info => {})
            @tb1.business_items = [item]
            @current_day.time_blocks = [@tb2]
            @longer_day.time_blocks = [@tb1]
            
            diff = @current_day.diff(@longer_day)
            
            item_changes = diff[:time_blocks].first[:business_items]
            item_changes.must_be_instance_of Array
            item_changes.must_equal [
                {:change_type => "deleted", 
                 :description => "1.  description goes here",
                 :position => 1, 
                 :pdf_info => {}}]
          end
        end
        
        describe "when a business item has been modified" do
          it "must return a change_type of 'modified' for the item" do
            item1 = BusinessItem.new(:description => "1.  description goes here", :position => 1)
            item2 = BusinessItem.new(:description => "1.  description goes here", :position => 1, :note => "note added")
            @tb1.business_items = [item1]
            @tb2.business_items = [item2]
            @current_day.time_blocks = [@tb1]
            @longer_day.time_blocks = [@tb2]
            
            diff = @current_day.diff(@longer_day)
            item_changes = diff[:time_blocks].first[:business_items]
            item_changes.first[:change_type].must_equal "modified"
          end
          
          it "must see a positional change as a modification, despite the effect on the description text" do
            item1 = BusinessItem.new(:description => "1.  description goes here", :position => 1)
            item2 = BusinessItem.new(:description => "2.  description goes here", :position => 2, :note => "note added")
            @tb1.business_items = [item1]
            @tb2.business_items = [item2]
            @current_day.time_blocks = [@tb1]
            @longer_day.time_blocks = [@tb2]
            
            diff = @current_day.diff(@longer_day)
            item_changes = diff[:time_blocks].first[:business_items]
            item_changes.first[:change_type].must_equal "modified"
          end
          
          it "must return the original values of the changed fields" do
            item1 = BusinessItem.new(:description => "1.  description goes here", :position => 1)
            item2 = BusinessItem.new(:description => "2.  description goes here")
            item2.position = 2
            item2.note = "note added"
            item2.pdf_info = {}
            
            @tb1.business_items = [item1]
            @tb2.business_items = [item2]
            @current_day.time_blocks = [@tb1]
            @longer_day.time_blocks = [@tb2]
            
            diff = @current_day.diff(@longer_day)
            item_changes = diff[:time_blocks].first[:business_items]
            item_changes.must_be_instance_of Array
            item_changes.must_equal [
              {:change_type => "modified", 
               :description => "2.  description goes here",
               :note => "note added",
               :position => 2,
               :pdf_info => {}
               }]
          end
          
          it "must report a block as modified when only a business item has been altered" do
            day1 = SittingDay.new
            day2 = SittingDay.new
            tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1)
            tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1)
            item1 = BusinessItem.new(:description => "1.  description goes here", :position => 1)
            item2 = BusinessItem.new(:description => "2.  description goes here")
            tb1.business_items = [item1]
            tb2.business_items = [item2]
            day1.time_blocks = [tb1]
            day2.time_blocks = [tb2]
            
            diff = day1.diff(day2)
            diff[:time_blocks].first[:change_type].must_equal "modified"
          end
        end
      end
      
      it "must cope with complex time blocks changes" do
        tb0 = TimeBlock.new(:title => "Business in the Chamber at 10am", :position => 0)
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 3.30pm", :position => 1)
        tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 2)
        tb3 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1)
        tb4 = TimeBlock.new(:title => "Business in the Chamber at 3.30pm", :position => 2)
        tb5 = TimeBlock.new(:title => "Business in Grand Committee at 3.30pm", :position => 3)
        
        day1 = SittingDay.new()
        day1.time_blocks = [tb1, tb2, tb5]
        day2 = SittingDay.new()
        day2.time_blocks = [tb0, tb3, tb4]
        
        diff = day1.diff(day2)
        
        diff[:time_blocks].count.must_equal 4
        
        block0 = diff[:time_blocks][0]
        block1 = diff[:time_blocks][1]
        block2 = diff[:time_blocks][2]
        block3 = diff[:time_blocks][3]
        
        block0[:change_type].must_equal "modified"
        block0[:title].must_equal "Business in the Chamber at 3.30pm"
        block0[:position].must_equal 2
        
        block1[:change_type].must_equal "modified"
        block1[:title].must_equal "Business in the Chamber at 11.00am"
        block1[:position].must_equal 1
        
        block2[:change_type].must_equal "new"
        block2[:title].must_equal "Business in Grand Committee at 3.30pm"
        
        block3[:change_type].must_equal "deleted"
        block3[:title].must_equal "Business in the Chamber at 10am"
        block3[:position].must_equal 0
      end
      
      it "must cope with complex business_item changes" do
        day1 = SittingDay.new
        day2 = SittingDay.new
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1)
        tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1)
        
        item0 = BusinessItem.new(:description => "1.  surplus to requirements", :position => 1)
        item1 = BusinessItem.new(:description => "2.  description goes here", :position => 2)
        item2 = BusinessItem.new(:description => "1.  description goes here", :position => 1)
        item3 = BusinessItem.new(:description => "2.  hello, I'm new", :position => 2)
        
        tb1.business_items = [item2, item3]
        tb2.business_items = [item0, item1]
        day1.time_blocks = [tb1]
        day2.time_blocks = [tb2]
        
        diff = day1.diff(day2)
        
        diff[:time_blocks].count.must_equal 1
        diff[:time_blocks].first[:business_items].count.must_equal 3
        
        diffs = diff[:time_blocks].first[:business_items]
        diff0 = diffs[0]
        diff1 = diffs[1]
        diff2 = diffs[2]
        
        diff0[:change_type].must_equal "modified"
        diff0[:description].must_equal "2.  description goes here"
        diff0[:position].must_equal 2
        
        diff1[:change_type].must_equal "new"
        diff1[:description].must_equal "2.  hello, I'm new"
        
        diff2[:change_type].must_equal "deleted"
        diff2[:description].must_equal "1.  surplus to requirements"
      end
    end
  end
end