#encoding: utf-8

require './spec/minitest_helper.rb'
require './lib/parser'

class ParserTest < MiniTest::Spec
  describe "Parser", "when given the Forthcoming Business for 27th March 2013 PDF as FB-TEST.PDF" do
    before do
      @@parser ||= Parser.new("./data/FB-TEST.pdf")
      @parser = @@parser
    end
    
    describe "in general" do
      it "must return a Parser" do
        @parser.must_be_instance_of Parser
      end
    end
    
    describe "when asked to process the document" do
      before do
        @@doc_processed ||= false
        unless @@doc_processed
          CalendarDay.delete_all
          @parser.process
          @@doc_processed = true
        end
      end
      
      it "should not duplicate the items" do
        CalendarDay.all.count.must_equal 14
        @parser.process
        CalendarDay.all.count.must_equal 14
      end
      
      it "must find all (8) pages of content" do
        @parser.pages.length.must_equal 8
      end
      
      it "must create a CalendarDay for each date (14 days)" do
        CalendarDay.all.count.must_equal(14)
      end
      
      it "must create expected SittingDays (11)" do
        SittingDay.all.count.must_equal 11
      end
      
      it "must create expected NonSittingDays (3)" do
        NonSittingDay.all.count.must_equal 3
      end
      
      it "must create all the TimeBlocks (23)" do
        days = SittingDay.all
        blocks = days.map { |x| x.time_blocks }.flatten
        blocks.count.must_equal(23)
      end
      
      it "must create all the BusinessItems (43)" do
        days = SittingDay.all
        blocks = days.map { |x| x.time_blocks }.flatten
        items = blocks.map { |x| x.business_items }.flatten
        items.count.must_equal 43
      end
      
      describe "the created object for Wednesday 27 March" do
        before do
          @sitting_day = SittingDay.where(:date => Time.parse("2013-03-27 00:00:00Z")).first
        end
        
        it "must have a sensible ID" do
          @sitting_day.id.must_equal("CalendarDay_2013-03-27")
        end
        
        it "must not be flagged as provisional" do
          @sitting_day.is_provisional.wont_equal true
        end
        
        it "must have the pdf file name (FB-TEST.pdf)" do
          @sitting_day.pdf_info[:filename].must_equal 'FB-TEST.pdf'
        end
        
        it "must store the pdf last edited datetime" do
          @sitting_day.pdf_info[:last_edited].must_equal Time.parse("D:20130328102303Z")
        end
        
        it "must start on line 10 of page 1" do
          @sitting_day.pdf_info[:page].must_equal 1
          @sitting_day.pdf_info[:line].must_equal 10
        end
               
        it "must have two (2) TimeBlocks" do
          @sitting_day.time_blocks.length.must_equal 2
        end
        
        it "must generate sensible ids for the TimeBlocks" do
          @sitting_day.time_blocks.first.id.must_equal "TimeBlock_chamber_1100"
          @sitting_day.time_blocks.last.id.must_equal "TimeBlock_grand_committee_1545"
        end
        
        it "must have a first TimeBlock entitled 'Business in the Chamber at 11.00am'" do
          @sitting_day.time_blocks.first.title.must_equal "Business in the Chamber at 11.00am"
        end
        
        it "must have a first TimeBlock with a time_as_number of '1100'" do
          @sitting_day.time_blocks.first.time_as_number.must_equal 1100
        end
        
        it "must have a first TimeBlock not marked as provisional" do
          @sitting_day.time_blocks.first.is_provisional.wont_equal true
        end
                
        it "must have a last TimeBlock entitled 'Business in Grand Committee at 3.45pm'" do
          @sitting_day.time_blocks.last.title.must_equal "Business in Grand Committee at 3.45pm"
        end
          
        it "must have a last TimeBlock with a time_as_number of '1545'" do
          @sitting_day.time_blocks.last.time_as_number.must_equal 1545
        end
        
        it "must record the position of each TimeBlock" do
          @sitting_day.time_blocks.first.position.must_equal 1
          @sitting_day.time_blocks.last.position.must_equal 2
        end
        
        describe "when looking at 'Business in the Chamber at 11.00am'" do
          before do
            @time = @sitting_day.time_blocks.first
          end
          
          it "must start on line 12 of page 1" do
            @time.pdf_info[:page].must_equal 1
            @time.pdf_info[:line].must_equal 12
          end
          
          it "must have four (4) items" do
            @time.business_items.length.must_equal 4
          end
          
          it "must have business starting on line 17 of page 1" do
            @time.business_items[2].pdf_info[:page].must_equal 1
            @time.business_items[2].pdf_info[:line].must_equal 17
          end
          
          it "must record the positions of the business items" do
            @time.business_items[0].position.must_equal 1
            @time.business_items[1].position.must_equal 2
            @time.business_items[2].position.must_equal 3
            @time.business_items[3].position.must_equal 4
          end
          
          it "must not have any notes" do
            @time.note.must_be_nil
          end
          
          it "must have a first item with an id of BusinessItem_oral_questions" do
            @time.business_items[0]["_id"].must_equal "BusinessItem_oral_questions"
          end
          
          it "must have a first item with the description '1.  Oral questions (30 minutes)'" do
            @time.business_items[0]["description"].must_equal "1.  Oral questions (30 minutes)"
          end
        end
        
        describe "when looking at 'Business in Grand Committee at 3.45pm'" do
          before do
            @time = @sitting_day.time_blocks.last
          end
          
          it "must start on line 23 of page 1" do
            @time.pdf_info[:page].must_equal 1
            @time.pdf_info[:line].must_equal 23
          end
          
          it "must have no business items" do
            @time.business_items.length.must_equal 0
          end
          
          it "must have a note with the text 'No business scheduled'" do
            @time.note.must_equal "No business scheduled"
          end
        end
      end
      
      describe "the created object for Wednesday 8 May" do
        before do
          @sitting_day = SittingDay.where(:date => Time.parse("2013-05-08 00:00:00Z")).first
        end
        
        it "must be flagged as provisional" do
          @sitting_day.is_provisional.must_equal true
        end
        
        it "must have three TimeBlocks" do
          @sitting_day.time_blocks.length.must_equal 3
        end
        
        it "the first TimeBlock should be flagged as provisional" do
          @sitting_day.time_blocks[0].is_provisional.must_equal true
        end
        
        it "the second TimeBlock should be flagged as provisional" do
          @sitting_day.time_blocks[1].is_provisional.must_equal true
        end
        
        it "the third TimeBlock should be flagged as provisional" do
          @sitting_day.time_blocks[2].is_provisional.must_equal true
        end
      end
    end
  end
  
  describe "Parser", "when given the Forthcoming Business for 9th May 2013 PDF as FB-TEST-2.PDF" do
    before do
      @@parser2 ||= Parser.new("./data/FB-TEST-2.pdf")
      @parser = @@parser2
    end
    
    describe "when asked to process the document" do
      before do
        @@doc2_processed ||= false
        unless @@doc2_processed
          CalendarDay.delete_all
          @parser.process
          @@doc2_processed = true
        end
      end
      
      it "must create the expected number of days" do
        CalendarDay.all.count.must_equal 16
      end
      
      it "must cope with business items scheduled for 12 noon" do
        sitting_day = SittingDay.where(:date => Time.parse("2013-05-22 00:00:00Z")).first
        sitting_day.time_blocks[1].time_as_number.must_equal 1200
      end
      
      it "must cope with simple marshalled list notes" do
        sitting_day = CalendarDay.where(:date => Time.parse("2013-05-31 00:00:00Z")).first
        sitting_day.note.must_equal "Last day to table amendments for the marshalled list for: Care Bill - Committee Day 1"
      end
      
      it "must cope with multi-line marshalled list notes" do
        sitting_day = SittingDay.where(:date => Time.parse("2013-06-03 00:00:00Z")).first
        sitting_day.note.must_equal "House dinner in the Peers’ Dining Room at 7.30pm; Last day to table amendments for the marshalled list for: Rehabilitation of Offenders Bill - Committee Day 1; Mesothelioma Bill – Committee Day 1"
      end
      
      it "should mark 9 of the sitting days as provisional" do
        sitting_day = CalendarDay.where(:is_provisional => true)
        sitting_day.count.must_equal 9
      end
            
      it "should not append the page number to the last business item on the page" do
        # 2013-06-05, "Business in Grand Committee at 3.45pm", Lord Freud 6
        sitting_day = SittingDay.where(:date => Time.parse("2013-06-05 000:000:00Z")).first
        block = sitting_day.time_blocks.last
        block.business_items.first.description.must_equal "1.  Mesothelioma Bill [HL] – Committee (Day 1) – Lord Freud"
      end
    end
  end
  
  describe "Parser", "when given consecutive Forthcoming Business documents where one overrides the other" do
    before do
      @@parser3 ||= Parser.new("./data/FB 2013 03 13.pdf")
      @@doc3_processed ||= false
      unless @@doc3_processed
        CalendarDay.delete_all
        @@parser3.process
        @@parser3 = Parser.new("./data/FB 2013 03 20 r.pdf")
        @@parser3.process
        @@doc3_processed = true
      end
    end
    
    it "should create the expected number of sitting days" do
      CalendarDay.all.count.must_equal 24
    end
    
    it "should capture the changes" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-03-25 00:00:00Z")).first
      sitting_day.diffs.must_be_instance_of Array
      sitting_day.diffs.wont_be_empty
    end
    
    it "should return empty diffs where no changes have been made" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-05-09 00:00:00Z")).first
      sitting_day.diffs.must_be_empty
    end
    
    it "should replace the older content with the new version" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-03-25 00:00:00Z")).first
      sitting_day.time_blocks.count.must_equal 2
      sitting_day.time_blocks[0].business_items.count.must_equal 4
      sitting_day.time_blocks[1].business_items.count.must_equal 6
    end
    
    it "should remove provisional status where elements are no longer down as provisional" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-03-25 00:00:00Z")).first
      sitting_day.is_provisional.wont_equal true
    end
    
    it "should record the previous provisional status in the diffs" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-03-25 00:00:00Z")).first
      diff = sitting_day.diffs.first
      
      diff["time_blocks"].first["is_provisional"].must_equal true
      diff["time_blocks"].last["is_provisional"].must_equal true
    end
    
    it "should register a modification where the text has changed" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-04-24 00:00:00Z")).first
      diff = sitting_day.diffs.first
      
      diff["time_blocks"].count.must_equal 1
      diff["time_blocks"][0]["business_items"].count.must_equal 2
      
      bus_items = diff["time_blocks"][0]["business_items"]
      bus_items[0]["change_type"].must_equal "modified"
      bus_items[0]["description"].must_equal("1.  QSD on Personal, Social and Health education in schools – Baroness Massey of Darwen/Lord Nash (time limit 1 hour)")
      bus_items[1]["description"].must_equal("3.  Further business will be scheduled")
    end
    
    it "should report business_items displaced by an insertion as modified" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-03-25 00:00:00Z")).first
      diff = sitting_day.diffs.first
      time_block = diff["time_blocks"][1]
      time_block["business_items"][0]["change_type"].must_equal "new"
      time_block["business_items"][1]["change_type"].must_equal "modified"
      time_block["business_items"][1]["position"].must_equal 1
      time_block["business_items"][1]["description"].must_equal "1.  Draft CRC Energy Efficiency Scheme Order 2013 – Baroness Verma"
    end
    
  end
  
  describe "Parser", "when given consecutive Forthcoming Business documents in reverse order" do
    before do
      @@parser4 ||= Parser.new("./data/FB 2013 03 20 r.pdf")
      @@doc4_processed ||= false
      unless @@doc4_processed
        CalendarDay.delete_all
        @@parser4.process
        @@parser4 = Parser.new("./data/FB 2013 03 13.pdf")
        @@parser4.process
        @@doc4_processed = true
      end
    end
    
    it "should create the expected number of calendar days" do
      CalendarDay.all.count.must_equal 24
    end
    
    it "should create the expected number of sitting days" do
      SittingDay.all.count.must_equal 19
    end
    
    it "should create the expected number of non-sitting days" do
      NonSittingDay.all.count.must_equal 5
    end
    
    it "should not replace new content with the older version" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-03-25 00:00:00Z")).first
      sitting_day.time_blocks.count.must_equal 2
      sitting_day.time_blocks[0].business_items.count.must_equal 4
      sitting_day.time_blocks[1].business_items.count.must_equal 6
    end
  end
end