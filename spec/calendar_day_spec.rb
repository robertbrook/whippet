#encoding: utf-8

require './spec/rspec_helper.rb'
require './models/calendar_day'

describe CalendarDay do
  context "in general" do
    it "should allow casting from CalendarDay to SittingDay" do
      day = CalendarDay.new(:note => "test")
      sitting_day = day.becomes(SittingDay)
      sitting_day.should be_an_instance_of(SittingDay)
    end
    
    it "should cast CalendarDay to SittingDay retaining note text" do
      day = CalendarDay.new(:note => "test")
      sitting_day = day.becomes(SittingDay)
      sitting_day.note.should eq "test"
    end
    
    it "should allow casting from CalendarDay to NonSittingDay" do
      old_day = CalendarDay.new()
      new_day = old_day.becomes(NonSittingDay)
      new_day.should be_an_instance_of(NonSittingDay)
    end
    
    it "should return false for has_time_blocks? if not a SittingDay" do
      ns = NonSittingDay.new
      ns.has_time_blocks?.should eq false
    end
    
    it "should return false for has_time_blocks? if a SittingDay has no time_blocks" do
      sit = SittingDay.new
      sit.has_time_blocks?.should eq false
    end
    
    it "should return true for has_time_blocks? if a SittingDay has 1 or more time_blocks" do
      sit = SittingDay.new
      sit.time_blocks = [TimeBlock.new]
      sit.has_time_blocks?.should eq true
    end
  end
  
  context "when asked for the source documents" do
    before :each do
      @day = SittingDay.new
      @day.pdf_info = {:filename => "file.pdf"}
    end
    
    it "should return an array with the primary source as the first element" do
      time_block = TimeBlock.new()
      item1 = BusinessItem.new(:pdf_info => {:filename => "file2.pdf"})
      item2 = BusinessItem.new(:pdf_info => {:filename => "file3.pdf"})
      time_block.business_items = [item1, item2]
      @day.time_blocks = [time_block]
      @day.source_docs.should eq ["file.pdf", "file2.pdf", "file3.pdf"]
    end
    
    it "should not return duplicate file names" do
      time_block = TimeBlock.new()
      item1 = BusinessItem.new(:pdf_info => {:filename => "file2.pdf"})
      item2 = BusinessItem.new(:pdf_info => {:filename => "file2.pdf"})
      time_block.business_items = [item1, item2]
      @day.time_blocks = [time_block]
      @day.source_docs.should eq ["file.pdf", "file2.pdf"]
    end
    
    it "should not return nil where there is no filename" do
      time_block = TimeBlock.new()
      item1 = BusinessItem.new(:pdf_info => {:filename => "file2.pdf"})
      item2 = BusinessItem.new()
      time_block.business_items = [item1, item2]
      @day.time_blocks = [time_block]
      @day.source_docs.should eq ["file.pdf", "file2.pdf"]
    end
    
    it "should return a single element array when there is only one source pdf" do
      @day.source_docs.should eq ["file.pdf"]
    end
  end
  
  context "when asked for diffs" do
    it "should throw an error when asked to diff with an object not derived from CalendarDay" do
      day = SittingDay.new
      expect{day.diff("test")}.to raise_error(RuntimeError, "Unable to compare SittingDay to String")
    end
    
    it "should return an empty Hash if there is no significant difference between the 2 objects" do
      day = SittingDay.new
      day2 = SittingDay.new
      (day2 == day).should eq false
      day.diff(day2).should be_empty
    end
    
    it "should return the original values for each of the simple attributes that have changed" do
      current_day = SittingDay.new(:accepted => true)
      previous_day = NonSittingDay.new(:note => "House not expected to sit", :accepted => false, :is_provisional => false)
      diff = current_day.diff(previous_day)
      
      diff[:note].should eq "House not expected to sit"
      diff[:accepted].should eq false
      diff[:is_provisional].should eq false
      diff[:_type].should eq "NonSittingDay"
    end
    
    it "should not return a list of changes if the time blocks are the same" do
      tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :id => "chamber_1100")
      tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :id => "chamber_1100")
      day1 = SittingDay.new()
      day2 = SittingDay.new()
      day1.time_blocks = [tb1]
      day2.time_blocks = [tb2]
      day1.diff(day2).should be_empty
    end
    
    context "when a time block is added" do
      it "should return change_type of 'new' for the block" do
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :id => "chamber_1100")
        tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm", :id => "grand_committee_1545")
        current_day = SittingDay.new()
        shorter_day = SittingDay.new()
        shorter_day.time_blocks = [tb1]
        current_day.time_blocks = [tb1, tb2]
        
        diff = current_day.diff(shorter_day)
        
        block_changes = diff[:time_blocks]
        block_changes.first[:change_type].should eq "new"
      end
      
      it "should return the title for the block" do
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :id => "chamber_1100")
        tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm", :id => "grand_committee_1545")
        current_day = SittingDay.new()
        shorter_day = SittingDay.new()
        shorter_day.time_blocks = [tb1]
        current_day.time_blocks = [tb1, tb2]
        
        diff = current_day.diff(shorter_day)
        
        block_changes = diff[:time_blocks]
        block_changes.should be_an_instance_of Array
        block_changes.should eq [
          {:change_type => "new",
           :id => "grand_committee_1545",
           :title => "Business in Grand Committee at 3.45pm"}]
      end
    end
    
    context "when a time block is deleted" do
      it "should return a change_type of 'deleted' for the block" do
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :id => "chamber_1100")
        tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm", :id => "grand_committee_1545")
        tb2.position = 2
        
        longer_day = SittingDay.new()
        current_day = SittingDay.new()
        current_day.time_blocks = [tb1]
        longer_day.time_blocks = [tb1, tb2]
        
        diff = current_day.diff(longer_day)
        
        block_changes = diff[:time_blocks]
        block_changes.first[:change_type].should eq "deleted"
      end
      
      it "should return all the details of the deleted block" do
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :id => "chamber_1100")
        tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm", :id => "grand_committee_1545")
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
        block_changes.should eq [
          {:change_type => "deleted",
           :id => "grand_committee_1545",
           :title => "Business in Grand Committee at 3.45pm",
           :position => 2,
           :pdf_info=>{"filename"=>"FB-TEST.pdf", "page"=>1, "line"=>29, "last_edited"=>"2013-03-28T10:23:03Z"}}]
      end
      
      it "should return all the business_item data for removed time_blocks" do
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :id => "chamber_1100")
        tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm", :id => "chamber_1545")
        tb2.position = 2
        item = BusinessItem.new(:description => "Further business will be scheduled", :position => 1)
        tb2.business_items = [item]
        
        longer_day = SittingDay.new()
        current_day = SittingDay.new()
        current_day.time_blocks = [tb1]
        longer_day.time_blocks = [tb1, tb2]
        
        diff = current_day.diff(longer_day)
        
        block_change = diff[:time_blocks].first
        block_change[:change_type].should eq "deleted"
        item_changes = block_change[:business_items]
        item_changes.should be_an_instance_of Array
        item_changes.length.should eq 1
        change = item_changes.first
        change[:change_type].should eq "deleted"
        change[:description].should eq "Further business will be scheduled"
        change[:position].should eq 1
      end
    end
    
    context "when a block is modified" do
      before do
        @tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1, :id => "chamber_1100")
        @tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 2, :id => "chamber_1100")
        @longer_day = SittingDay.new()
        @current_day = SittingDay.new()
      end
      
      it "should return a change_type of 'modified' for the block" do
        @current_day.time_blocks = [@tb1]
        @longer_day.time_blocks = [@tb2]
        
        diff = @current_day.diff(@longer_day)
        
        block_changes = diff[:time_blocks]
        block_changes.first[:change_type].should eq "modified"
      end
      
      context "when a business item has been added" do
        it "should return a change_type of 'new' for the item" do
          item = BusinessItem.new(:description => "1.  description goes here", :position => 1, :id => "id")
          @tb1.business_items = [item]
          @current_day.time_blocks = [@tb1]
          @longer_day.time_blocks = [@tb2]
          
          diffs = @current_day.diff(@longer_day)
          item_changes = diffs[:time_blocks].first[:business_items]
          item_changes.first[:change_type].should eq "new"
        end
        
        it "should return the description for the item" do
          item = BusinessItem.new(:description => "1.  description goes here", :position => 1, :id => "id")
          @tb1.business_items = [item]
          @current_day.time_blocks = [@tb1]
          @longer_day.time_blocks = [@tb2]
          
          diff = @current_day.diff(@longer_day)
          
          item_changes = diff[:time_blocks].first[:business_items]
          item_changes.should be_an_instance_of Array
          item_changes.should eq [{:change_type => "new", :id => "id", :description => "1.  description goes here"}]
        end
      end
      
      context "when a business item has been deleted" do
        it "should return a change_type of 'deleted' for the item" do
          item = BusinessItem.new(:description => "1.  description goes here", :position => 1, :id => "id")
          @tb1.business_items = [item]
          @current_day.time_blocks = [@tb2]
          @longer_day.time_blocks = [@tb1]
          
          diff = @current_day.diff(@longer_day)
          
          item_changes = diff[:time_blocks].first[:business_items]
          item_changes.first[:change_type].should eq "deleted"
        end
        
        it "should return all the details of the original item" do
          item = BusinessItem.new(:description => "1.  description goes here", :position => 1, :pdf_info => {}, :id => "id")
          @tb1.business_items = [item]
          @current_day.time_blocks = [@tb2]
          @longer_day.time_blocks = [@tb1]
          
          diff = @current_day.diff(@longer_day)
          
          item_changes = diff[:time_blocks].first[:business_items]
          item_changes.should be_an_instance_of Array
          item_changes.should eq [
              {:change_type => "deleted",
               :id => "id",
               :description => "1.  description goes here",
               :position => 1, 
               :pdf_info => {}}]
        end
      end
      
      context "when a business item has been modified" do
        it "should return a change_type of 'modified' for the item" do
          item1 = BusinessItem.new(:description => "1.  description goes here", :position => 1, :id => "id")
          item2 = BusinessItem.new(:description => "1.  description goes here", :position => 1, :note => "note added", :id => "id")
          @tb1.business_items = [item1]
          @tb2.business_items = [item2]
          @current_day.time_blocks = [@tb1]
          @longer_day.time_blocks = [@tb2]
          
          diff = @current_day.diff(@longer_day)
          item_changes = diff[:time_blocks].first[:business_items]
          item_changes.first[:change_type].should eq "modified"
        end
        
        it "should see a positional change as a modification, despite the effect on the description text" do
          item1 = BusinessItem.new(:description => "1.  description goes here", :position => 1, :id => "id")
          item2 = BusinessItem.new(:description => "2.  description goes here", :position => 2, :note => "note added", :id => "id")
          @tb1.business_items = [item1]
          @tb2.business_items = [item2]
          @current_day.time_blocks = [@tb1]
          @longer_day.time_blocks = [@tb2]
          
          diff = @current_day.diff(@longer_day)
          item_changes = diff[:time_blocks].first[:business_items]
          item_changes.first[:change_type].should eq "modified"
        end
        
        it "should return the original values of the changed fields" do
          item1 = BusinessItem.new(:description => "1.  description goes here", :position => 1, :id => "id")
          item2 = BusinessItem.new(:description => "2.  description goes here", :id => "id")
          item2.position = 2
          item2.note = "note added"
          item2.pdf_info = {}
          
          @tb1.business_items = [item1]
          @tb2.business_items = [item2]
          @current_day.time_blocks = [@tb1]
          @longer_day.time_blocks = [@tb2]
          
          diff = @current_day.diff(@longer_day)
          item_changes = diff[:time_blocks].first[:business_items]
          item_changes.should be_an_instance_of Array
          item_changes.should eq [
            {:change_type => "modified",
             :id => "id",
             :description => "2.  description goes here",
             :note => "note added",
             :position => 2,
             :pdf_info => {}
             }]
        end
        
        it "should report a block as modified when only a business item has been altered" do
          day1 = SittingDay.new
          day2 = SittingDay.new
          tb1 = TimeBlock.new(
            :title => "Business in the Chamber at 11.00am",
            :position => 1,
            :id => "chamber_1100")
          tb2   = TimeBlock.new(
              :title => "Business in the Chamber at 11.00am",
              :position => 1,
              :id => "chamber_1100")
          item1 = BusinessItem.new(
            :description => "1.  description goes here",
            :position => 1,
            :id => "BusinessItem_description_goes_here")
          item2 = BusinessItem.new(
            :description => "2.  description goes here", 
            :position => 2,
            :id => "BusinessItem_description_goes_here")
          tb1.business_items = [item1]
          tb2.business_items = [item2]
          day1.time_blocks = [tb1]
          day2.time_blocks = [tb2]
          
          diff = day1.diff(day2)
          diff[:time_blocks].first[:change_type].should eq "modified"
        end
      end
    end
    
    it "should cope with complex time blocks changes" do
      tb0 = TimeBlock.new(:title => "Business in the Chamber at 10am", :position => 0, :id => "chamber_1000")
      tb1 = TimeBlock.new(:title => "Business in the Chamber at 3.30pm", :position => 1, :id => "chamber_1530")
      tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 2, :id => "chamber_1100")
      tb3 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1, :id => "chamber_1100")
      tb4 = TimeBlock.new(:title => "Business in the Chamber at 3.30pm", :position => 2, :id => "chamber_1530")
      tb5 = TimeBlock.new(:title => "Business in Grand Committee at 3.30pm", :position => 3, :id => "gc_1530")
      
      day1 = SittingDay.new()
      day1.time_blocks = [tb1, tb2, tb5]
      day2 = SittingDay.new()
      day2.time_blocks = [tb0, tb3, tb4]
      
      diff = day1.diff(day2)
      
      diff[:time_blocks].count.should eq 4
      
      block0 = diff[:time_blocks][0]
      block1 = diff[:time_blocks][1]
      block2 = diff[:time_blocks][2]
      block3 = diff[:time_blocks][3]
      
      block0[:change_type].should eq "modified"
      block0[:title].should eq "Business in the Chamber at 3.30pm"
      block0[:position].should eq 2
      
      block1[:change_type].should eq "modified"
      block1[:title].should eq "Business in the Chamber at 11.00am"
      block1[:position].should eq 1
      
      block2[:change_type].should eq "new"
      block2[:title].should eq "Business in Grand Committee at 3.30pm"
      
      block3[:change_type].should eq "deleted"
      block3[:title].should eq "Business in the Chamber at 10am"
      block3[:position].should eq 0
    end
    
    it "should cope with complex business_item changes" do
      day1 = SittingDay.new
      day2 = SittingDay.new
      tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1, :id => "chamber_1100")
      tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1, :id => "chamber_1100")
      
      item0 = BusinessItem.new(:description => "1.  surplus to requirements", :position => 1, :id => "surplus")
      item1 = BusinessItem.new(:description => "2.  description goes here", :position => 2, :id => "desc_here")
      item2 = BusinessItem.new(:description => "1.  description goes here", :position => 1, :id => "desc_here")
      item3 = BusinessItem.new(:description => "2.  hello, I'm new", :position => 2, :id => "hello")
      
      tb1.business_items = [item2, item3]
      tb2.business_items = [item0, item1]
      day1.time_blocks = [tb1]
      day2.time_blocks = [tb2]
      
      diff = day1.diff(day2)
      
      diff[:time_blocks].count.should eq 1
      diff[:time_blocks].first[:business_items].count.should eq 3
      
      diffs = diff[:time_blocks].first[:business_items]
      diff0 = diffs[0]
      diff1 = diffs[1]
      diff2 = diffs[2]
      
      diff0[:change_type].should eq "modified"
      diff0[:description].should eq "2.  description goes here"
      diff0[:position].should eq 2
      
      diff1[:change_type].should eq "new"
      diff1[:description].should eq "2.  hello, I'm new"
      
      diff2[:change_type].should eq "deleted"
      diff2[:description].should eq "1.  surplus to requirements"
    end
  end
end

describe TimeBlock do
  context "when implying a place from a title" do
    it "should return a place of 'Westminster Hall' when given a title of 'Business in Westminster Hall at 3pm'" do
      my_time_block = TimeBlock.new()
      my_time_block.title = 'Business in Westminster Hall at 3pm'
      my_time_block.place.should eq 'Westminster Hall'
    end
    
    it "should not return a place of 'Westminster Hall' when given a title of 'Business in Westminster hall at 3pm'" do
      my_time_block = TimeBlock.new()
      my_time_block.title = 'Business in Westminster hall at 3pm'
      my_time_block.place.should_not eq 'Westminster Hall'
    end
  end
end

describe BusinessItem do
  context "when implying a name from a from a description" do
    it "should return an empty array if there are no names" do
      test_item = BusinessItem.new()
      test_item.description = "1. Oral questions (30 minutes)"
#       test_item.names = []
      pending("Not yet implemented")
    end
    
    it "should not return a name where there is no name information" do
      test_item = BusinessItem.new()
      test_item.description = "1. Oral questions (30 minutes)"
#       test_item.names.should eq ""
      pending("Not yet implemented")
    end
  end
end