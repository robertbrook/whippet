#encoding: utf-8

require './spec/rspec_helper.rb'
require './models/calendar_day'
require './models/time_block'
require './models/business_item'
require './models/speaker_list'
require 'date'

describe CalendarDay do
  context "in general" do
    it "should allow casting from CalendarDay to SittingDay" do
      day = CalendarDay.new(:note => "test")
      sitting_day = day.becomes(SittingDay)
      expect(sitting_day).to be_an_instance_of(SittingDay)
    end
    
    it "should cast CalendarDay to SittingDay retaining note text" do
      day = CalendarDay.new(:note => "test")
      sitting_day = day.becomes(SittingDay)
      expect(sitting_day.note).to eq("test")
      # sitting_day.note.should eq "test"
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
  
  context "when asked to check whether a date is a Non Sitting Friday" do
    it "should return true if given the date '2013-07-12'" do
      CalendarDay.non_sitting_friday?('2013-07-12').should eq true
    end

    it "should return false if given an invalid date" do
      CalendarDay.non_sitting_friday?("invalid").should eq false
    end
    
    it "should return false if the date is not a Friday" do
      CalendarDay.non_sitting_friday?("Monday 18 November 2013").should eq false
    end
    
    it "should return false if the date is in the sitting_fridays table" do
      result = mock("SittingFriday")
      SittingFriday.expects(:find_by).with(:date => Date.parse("5 July 2013")).returns(result)
      CalendarDay.non_sitting_friday?("5 July 2013").should eq false
    end
    
    it "should return false if the date is recorded as a sitting day" do
      result = mock("SittingDay")
      SittingFriday.expects(:find_by).with(:date => Date.parse("5 July 2013")).returns(nil)
      SittingDay.expects(:find_by).with(:date => Date.parse("5 July 2013")).returns(result)
      CalendarDay.non_sitting_friday?("5 July 2013").should eq false
    end
    
    it "should return true if given a Friday with no evidence to suggest it's a sitting day" do
      SittingFriday.expects(:find_by).with(:date => Date.parse("12 July 2013")).returns(nil)
      SittingDay.expects(:find_by).with(:date => Date.parse("12 July 2013")).returns(nil)
      CalendarDay.non_sitting_friday?("12 July 2013").should eq true
    end
  end
  
  context "when asked for the source documents" do
    before :each do
      @day = SittingDay.new
      @day.meta = {"pdf_info" => {"filename" => "file.pdf"}}
    end
    
    it "should return an array with the primary source as the first element" do
      time_block = TimeBlock.new()
      item1 = BusinessItem.new(:meta => {"pdf_info" => {"filename" => "file2.pdf"}})
      item2 = BusinessItem.new(:meta => {"pdf_info" => {"filename" => "file3.pdf"}})
      time_block.business_items = [item1, item2]
      @day.time_blocks = [time_block]
      @day.source_docs.should eq ["file.pdf", "file2.pdf", "file3.pdf"]
    end
    
    it "should not return duplicate file names" do
      time_block = TimeBlock.new()
      item1 = BusinessItem.new(:meta => {"pdf_info" => {"filename" => "file2.pdf"}})
      item2 = BusinessItem.new(:meta => {"pdf_info" => {"filename" => "file2.pdf"}})
      time_block.business_items = [item1, item2]
      @day.time_blocks = [time_block]
      @day.source_docs.should eq ["file.pdf", "file2.pdf"]
    end
    
    it "should not return nil where there is no filename" do
      time_block = TimeBlock.new()
      item1 = BusinessItem.new(:meta => {"pdf_info" => {"filename" => "file2.pdf"}})
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
      diff[:type].should eq "NonSittingDay"
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
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :ident => "chamber_1100")
        tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm", :ident => "grand_committee_1545")
        current_day = SittingDay.new()
        shorter_day = SittingDay.new()
        shorter_day.time_blocks = [tb1]
        current_day.time_blocks = [tb1, tb2]
        
        diff = current_day.diff(shorter_day)
        
        block_changes = diff[:time_blocks]
        block_changes.first[:change_type].should eq "new"
      end
      
      it "should return the title for the block" do
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :ident => "chamber_1100")
        tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm", :ident => "grand_committee_1545")
        current_day = SittingDay.new()
        shorter_day = SittingDay.new()
        shorter_day.time_blocks = [tb1]
        current_day.time_blocks = [tb1, tb2]
        
        diff = current_day.diff(shorter_day)
        
        block_changes = diff[:time_blocks]
        block_changes.should be_an_instance_of Array
        block_changes.should eq [
          {:change_type => "new",
           :ident => "grand_committee_1545"}]
      end
    end
    
    context "when a time block is deleted" do
      it "should return a change_type of 'deleted' for the block" do
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :ident => "chamber_1100")
        tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm", :ident => "grand_committee_1545")
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
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :ident => "chamber_1100")
        tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm", :ident => "grand_committee_1545")
        tb2.position = 2
        tb2.meta = {"pdf_info" => {
            "filename" => "FB-TEST.pdf",
            "page" => 1,
            "line" => 29,
            "last_edited" => "2013-03-28T10:23:03Z"
          }}
        
        longer_day = SittingDay.new()
        current_day = SittingDay.new()
        current_day.time_blocks = [tb1]
        longer_day.time_blocks = [tb1, tb2]
        
        diff = current_day.diff(longer_day)
        
        block_changes = diff[:time_blocks]
        block_changes.should eq [
          {:change_type => "deleted",
           :ident => "grand_committee_1545",
           :title => "Business in Grand Committee at 3.45pm",
           :position => 2,
           :meta => {"pdf_info"=>{"filename"=>"FB-TEST.pdf", "page"=>1, "line"=>29, "last_edited"=>"2013-03-28T10:23:03Z"}}}]
      end
      
      it "should return all the business_item data for removed time_blocks" do
        tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :ident => "chamber_1100")
        tb2 = TimeBlock.new(:title => "Business in Grand Committee at 3.45pm", :ident => "chamber_1545")
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
          item = BusinessItem.new(:description => "1.  description goes here", :position => 1, :ident => "id")
          @tb1.business_items = [item]
          @current_day.time_blocks = [@tb1]
          @longer_day.time_blocks = [@tb2]
          
          diff = @current_day.diff(@longer_day)
          
          item_changes = diff[:time_blocks].first[:business_items]
          item_changes.should be_an_instance_of Array
          item_changes.should eq [{:ident=>"id", :change_type=>"new"}]
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
          item = BusinessItem.new(:description => "1.  description goes here", :position => 1, :ident => "id")
          @tb1.business_items = [item]
          @current_day.time_blocks = [@tb2]
          @longer_day.time_blocks = [@tb1]
          
          diff = @current_day.diff(@longer_day)
          
          item_changes = diff[:time_blocks].first[:business_items]
          item_changes.should be_an_instance_of Array
          item_changes.should eq [
              {:change_type => "deleted",
               :ident => "id",
               :description => "1.  description goes here",
               :position => 1,
               :meta => nil}]
        end
      end
      
      context "when a business item has been modified" do
        it "should return a change_type of 'modified' for the item" do
          item1 = BusinessItem.new(:description => "1.  description goes here", :position => 1, :ident => "id")
          item2 = BusinessItem.new(:description => "1.  description goes here", :position => 1, :note => "note added", :ident => "id")
          @tb1.business_items = [item1]
          @tb2.business_items = [item2]
          @current_day.time_blocks = [@tb1]
          @longer_day.time_blocks = [@tb2]
          
          diff = @current_day.diff(@longer_day)
          item_changes = diff[:time_blocks].first[:business_items]
          item_changes.first[:change_type].should eq "modified"
        end
        
        it "should see a positional change as a modification, despite the effect on the description text" do
          item1 = BusinessItem.new(:description => "1.  description goes here", :position => 1, :ident => "id")
          item2 = BusinessItem.new(:description => "2.  description goes here", :position => 2, :note => "note added", :ident => "id")
          @tb1.business_items = [item1]
          @tb2.business_items = [item2]
          @current_day.time_blocks = [@tb1]
          @longer_day.time_blocks = [@tb2]
          
          diff = @current_day.diff(@longer_day)
          item_changes = diff[:time_blocks].first[:business_items]
          item_changes.first[:change_type].should eq "modified"
        end
        
        it "should return the original values of the changed fields" do
          item1 = BusinessItem.new(:description => "1.  description goes here", :position => 1, :ident => "id")
          item2 = BusinessItem.new(:description => "2.  description goes here", :ident => "id")
          item2.position = 2
          item2.note = "note added"
          
          @tb1.business_items = [item1]
          @tb2.business_items = [item2]
          @current_day.time_blocks = [@tb1]
          @longer_day.time_blocks = [@tb2]
          
          diff = @current_day.diff(@longer_day)
          item_changes = diff[:time_blocks].first[:business_items]
          item_changes.should be_an_instance_of Array
          item_changes.should eq [
            {:description => "2.  description goes here",
             :position => 2,
             :note => "note added",
             :ident => "id",
             :meta => nil,
             :change_type => "modified"
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
      tb0 = TimeBlock.new(:title => "Business in the Chamber at 10am", :position => 0, :ident => "chamber_1000")
      tb1 = TimeBlock.new(:title => "Business in the Chamber at 3.30pm", :position => 1, :ident => "chamber_1530")
      tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 2, :ident => "chamber_1100")
      tb3 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1, :ident => "chamber_1100")
      tb4 = TimeBlock.new(:title => "Business in the Chamber at 3.30pm", :position => 2, :ident => "chamber_1530")
      tb5 = TimeBlock.new(:title => "Business in Grand Committee at 3.30pm", :position => 3, :ident => "gc_1530")
      
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
      block0[:ident].should eq "chamber_1530"
      block0[:position].should eq 2
      
      block1[:change_type].should eq "modified"
      block1[:ident].should eq "chamber_1100"
      block1[:position].should eq 1
      
      block2[:change_type].should eq "new"
      block2[:ident].should eq "gc_1530"
      
      block3[:change_type].should eq "deleted"
      block3[:title].should eq "Business in the Chamber at 10am"
      block3[:position].should eq 0
    end
    
    it "should cope with complex business_item changes" do
      day1 = SittingDay.new
      day2 = SittingDay.new
      tb1 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1, :ident => "chamber_1100")
      tb2 = TimeBlock.new(:title => "Business in the Chamber at 11.00am", :position => 1, :ident => "chamber_1100")
      
      item0 = BusinessItem.new(:description => "1.  surplus to requirements", :position => 1, :ident => "surplus")
      item1 = BusinessItem.new(:description => "2.  description goes here", :position => 2, :ident => "desc_here")
      item2 = BusinessItem.new(:description => "1.  description goes here", :position => 1, :ident => "desc_here")
      item3 = BusinessItem.new(:description => "2.  hello, I'm new", :position => 2, :ident => "hello")
      
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
      diff1[:ident].should eq "hello"
      
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
      test_item.names.should eq []
    end
    
    it "should return an array of one name where the name is 'Lord McNally'" do
      test_item = BusinessItem.new()
      test_item.description = "2. Offender Rehabilitation Bill [HL] – Committee (Day 1) – Lord McNally"
      test_item.names.should eq ["Lord McNally"]
    end
    
    it "should return an array of one name where the name is 'Baroness Stowell of Beeston'" do
      test_item = BusinessItem.new()
      test_item.description = "2. Marriage (Same-sex couples) Bill – Second Reading – Baroness Stowell of Beeston"
      test_item.names.should eq ["Baroness Stowell of Beeston"]
    end
    
    it "should return an array of two names where the two names are present" do
#       pending("fix to regex")
      test_item = BusinessItem.new()
      test_item.description = "QSD on the effectiveness of the Charity Commission – Baroness Barker/Lord Wallace of Saltaire (time limit 1 hour)"
      expect(test_item.names).to eq ["Baroness Barker", "Lord Wallace of Saltaire"]
    end

  end
  
    context "when implying a time limit from a from a description" do
    
      it "should not identify a time limit when no time limit is present" do
          test_item = BusinessItem.new()
          test_item.description = "2. Marriage (Same-sex couples) Bill – Second Reading – Baroness Stowell of Beeston"
          test_item.timelimit.should eq ""
      end
      
      it "should identify a time limit when a time limit is present" do
          test_item = BusinessItem.new()
          test_item.description = "QSD on the effectiveness of the Charity Commission – Baroness Barker/Lord Wallace of Saltaire (time limit 1 hour)"
          test_item.timelimit.should eq "time limit 1 hour"
      end

    end
end