# encoding: utf-8

require './spec/rspec_helper.rb'
require './lib/pdf_parser'

describe PdfParser do

  context "when given the Forthcoming Business for 5th June 2014 PDF as FB%202014%2006%2005.pdf" do
    before(:all) do
      @parser = PdfParser.new("./data/FB%202014%2006%2005.pdf")
      CalendarDay.delete_all
      @parser.process()
      @parser = PdfParser.new("./data/FB%202014%2006%2005.pdf")
      @parser.process()
    end
    
    it "should create the expected number of calendar days" do
      CalendarDay.all.count.should eq 17
    end
  end


  context "when given the Forthcoming Business for 27th March 2013 PDF as FB-TEST.PDF" do
    before(:all) do
      @parser = PdfParser.new("./data/FB-TEST.pdf")
    end
    
    describe "in general" do
      it "should return a Parser" do
        @parser.should be_an_instance_of(PdfParser)
      end
    end
    
    describe "when asked to process the document" do
      before(:all) do
        CalendarDay.delete_all
        @parser.process()
      end
      
      it "should find all (8) pages of content" do
        @parser.pages.length.should eq 8
      end
      
      it "should create a CalendarDay for each date (14 days)" do
        CalendarDay.all.count.should eq(14)
      end
      
      it "should create expected SittingDays (11)" do
        SittingDay.all.count.should eq 11
      end
      
      it "should create expected NonSittingDays (3)" do
        NonSittingDay.all.count.should eq 3
      end
      
      it "should create all the TimeBlocks (23)" do
        days = SittingDay.all
        blocks = days.map { |x| x.time_blocks }.flatten
        blocks.count.should eq(23)
      end
      
      it "should create all the BusinessItems (43)" do
        days = SittingDay.all
        blocks = days.map { |x| x.time_blocks }.flatten
        items = blocks.map { |x| x.business_items }.flatten
        items.count.should eq 43
      end
      
      describe "the created object for Wednesday 27 March" do
        before(:all) do
          @sitting_day = SittingDay.where(:date => Time.parse("2013-03-27 00:00:00Z")).first
        end
        
        it "should have a sensible ident" do
          @sitting_day.ident.should eq("CalendarDay_2013-03-27")
        end
        
        it "should not be flagged as provisional" do
          @sitting_day.is_provisional.should_not eq true
        end
        
        it "should have the pdf file name (FB-TEST.pdf)" do
          @sitting_day.meta["pdf_info"]["filename"].should eq 'FB-TEST.pdf'
        end
        
        it "should store the pdf last edited datetime" do
          Time.parse(@sitting_day.meta["pdf_info"]["last_edited"]).should eq Time.parse("D:20130328102303Z")
        end
        
        it "should start on line 11 of page 1" do
          @sitting_day.meta["pdf_info"]["page"].should eq 1
          @sitting_day.meta["pdf_info"]["line"].should eq 11
        end
               
        it "should have two (2) TimeBlocks" do
          @sitting_day.time_blocks.length.should eq 2
        end
        
        it "should generate sensible idents for the TimeBlocks" do
          @sitting_day.time_blocks.first.ident.should eq "TimeBlock_chamber_1100"
          @sitting_day.time_blocks.last.ident.should eq "TimeBlock_grand_committee_1545"
        end
        
        it "should have a first TimeBlock entitled 'Business in the Chamber at 11.00am'" do
          @sitting_day.time_blocks.first.title.should eq "Business in the Chamber at 11.00am"
        end
        
        it "should have a first TimeBlock with a time_as_number of '1100'" do
          @sitting_day.time_blocks.first.time_as_number.should eq 1100
        end
        
        it "should have a last TimeBlock entitled 'Business in Grand Committee at 3.45pm'" do
          @sitting_day.time_blocks.last.title.should eq "Business in Grand Committee at 3.45pm"
        end
          
        it "should have a last TimeBlock with a time_as_number of '1545'" do
          @sitting_day.time_blocks.last.time_as_number.should eq 1545
        end
        
        it "should record the position of each TimeBlock" do
          @sitting_day.time_blocks.first.position.should eq 1
          @sitting_day.time_blocks.last.position.should eq 2
        end
        
        describe "when looking at 'Business in the Chamber at 11.00am'" do
          before(:each) do
            @time = @sitting_day.time_blocks.first
          end
          
          it "should start on line 13 of page 1" do
            @time.meta["pdf_info"]["page"].should eq 1
            @time.meta["pdf_info"]["line"].should eq 13
          end
          
          it "should have four (4) items" do
            @time.business_items.length.should eq 4
          end
          
          it "should have business starting on line 18 of page 1" do
            @time.business_items[2].meta["pdf_info"]["page"].should eq 1
            @time.business_items[2].meta["pdf_info"]["line"].should eq 18
          end
          
          it "should record the positions of the business items" do
            @time.business_items[0].position.should eq 1
            @time.business_items[1].position.should eq 2
            @time.business_items[2].position.should eq 3
            @time.business_items[3].position.should eq 4
          end
          
          it "should not have any notes" do
            @time.note.should be_nil
          end
          
          it "should have a first item with an id of BusinessItem_oral_questions" do
            @time.business_items[0]["ident"].should eq "BusinessItem_oral_questions"
          end
          
          it "should have a first item with the description '1.  Oral questions (30 minutes)'" do
            item = @time.business_items[0]
            item["description"].should eq "1.  Oral questions (30 minutes)"
            item.meta["pdf_info"]["last_line"].should eq 14
          end
          
          it "should have a second item with the correct description spanning lines 15-17" do
            item = @time.business_items[1]
            item["description"].should eq "2.  Draft Legal Aid, Sentencing and Punishment of Offenders Act 2012 (Amendment of Schedule 1) Order 2013 – Motion to Regret – Lord Bach/Lord McNally"
            item.meta["pdf_info"]["line"].should eq 15
            item.meta["pdf_info"]["last_line"].should eq 17
          end
        end
                
        describe "when looking at 'Business in Grand Committee at 3.45pm'" do
          before(:each) do
            @time = @sitting_day.time_blocks.last
          end
          
          it "should start on line 24 of page 1" do
            @time.meta["pdf_info"]["page"].should eq 1
            @time.meta["pdf_info"]["line"].should eq 24
          end
          
          it "should have no business items" do
            @time.business_items.length.should eq 0
          end
          
          it "should have a note with the text 'No business scheduled'" do
            @time.note.should eq "No business scheduled"
          end
        end
      end
      
      describe "the created object for Wednesday 8 May" do
        before(:all) do
          @sitting_day = SittingDay.where(:date => Time.parse("2013-05-08 00:00:00Z")).first
        end
        
        it "should be flagged as provisional" do
          @sitting_day.is_provisional.should eq true
        end
        
        it "should have three TimeBlocks" do
          @sitting_day.time_blocks.length.should eq 3
        end
      end
    end
  end
  
  context "when given the Forthcoming Business for 9th May 2013 PDF as FB-TEST-2.PDF" do
    before(:all) do
      @parser = PdfParser.new("./data/FB-TEST-2.pdf")
    end
    
    describe "when asked to process the document" do
      before(:all) do
        CalendarDay.delete_all
        @parser.process()
      end
      
      it "should create the expected number of days" do
        CalendarDay.all.count.should eq 16
      end
      
      it "should cope with business items scheduled for 12 noon" do
        sitting_day = SittingDay.where(:date => Time.parse("2013-05-22 00:00:00Z")).first
        sitting_day.time_blocks[1].time_as_number.should eq 1200
      end
      
      it "should cope with simple marshalled list notes" do
        sitting_day = CalendarDay.where(:date => Time.parse("2013-05-31 00:00:00Z")).first
        sitting_day.note.should eq "Last day to table amendments for the marshalled list for: Care Bill - Committee Day 1"
      end
      
      it "should cope with multi-line marshalled list notes" do
        sitting_day = SittingDay.where(:date => Time.parse("2013-06-03 00:00:00Z")).first
        sitting_day.note.should eq "House dinner in the Peers’ Dining Room at 7.30pm; Last day to table amendments for the marshalled list for: Rehabilitation of Offenders Bill - Committee Day 1; Mesothelioma Bill – Committee Day 1"
      end
      
      it "should mark 9 of the sitting days as provisional" do
        sitting_day = CalendarDay.where(:is_provisional => true)
        sitting_day.count.should eq 9
      end
            
      it "should not append the page number to the last business item on the page" do
        # 2013-06-05, "Business in Grand Committee at 3.45pm", Lord Freud 6
        sitting_day = SittingDay.where(:date => Time.parse("2013-06-05 000:000:00Z")).first
        block = sitting_day.time_blocks.last
        block.business_items.first.description.should eq "1.  Mesothelioma Bill [HL] – Committee (Day 1) – Lord Freud"
      end
    end
  end
  
  context "when given consecutive Forthcoming Business documents where one overrides the other" do
    before(:all) do
      @parser = PdfParser.new("./data/FB 2013 03 13.pdf")
      CalendarDay.delete_all
      @parser.process()
      @parser = PdfParser.new("./data/FB 2013 03 20 r.pdf")
      @parser.process()
    end
    
    it "should create the expected number of sitting days" do
      CalendarDay.all.count.should eq 24
    end
    
    it "should capture the changes" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-03-25 00:00:00Z")).first
      sitting_day.history["diffs"].should be_an_instance_of(Array)
      sitting_day.history["diffs"].should_not be_empty
    end
    
    it "should return empty diffs where no changes have been made" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-05-09 00:00:00Z")).first
      sitting_day.history.should be_nil
    end
    
    it "should replace the older content with the new version" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-03-25 00:00:00Z")).first
      sitting_day.time_blocks.count.should eq 2
      sitting_day.time_blocks[0].business_items.count.should eq 4
      sitting_day.time_blocks[1].business_items.count.should eq 6
    end
    
    it "should remove provisional status where elements are no longer down as provisional" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-03-25 00:00:00Z")).first
      sitting_day.is_provisional.should be_nil
    end
    
    it "should register a modification where the text has changed" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-04-24 00:00:00Z")).first
      diff = sitting_day.history["diffs"].first
      
      diff["time_blocks"].count.should eq 1
      diff["time_blocks"][0]["business_items"].count.should eq 2
      
      bus_items = diff["time_blocks"][0]["business_items"]
      bus_items[0]["change_type"].should eq "modified"
      bus_items[0]["description"].should eq("1.  QSD on Personal, Social and Health education in schools – Baroness Massey of Darwen/Lord Nash (time limit 1 hour)")
      bus_items[1]["description"].should eq("3.  Further business will be scheduled")
    end
    
    it "should capture the line number correctly" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-03-26 00:00:00Z")).first
      sitting_day.meta["pdf_info"]["line"].should eq 1
      sitting_day.time_blocks[0].meta["pdf_info"]["line"].should eq 4
    end
    
    it "should report business_items displaced by an insertion as modified" do
      sitting_day = CalendarDay.find_by_date(Time.parse("2013-03-25"))
      diff = sitting_day.history["diffs"][0]
      time_block = diff["time_blocks"][1]
      time_block["business_items"][0]["change_type"].should eq "new"
      time_block["business_items"][1]["change_type"].should eq "modified"
      time_block["business_items"][1]["position"].should eq 1
      time_block["business_items"][1]["description"].should eq "1.  Draft CRC Energy Efficiency Scheme Order 2013 – Baroness Verma"
    end
  end
  
  context "when given consecutive Forthcoming Business documents in reverse order" do
    before(:all) do
      @parser = PdfParser.new("./data/FB 2013 03 20 r.pdf")
      CalendarDay.delete_all
      @parser.process()
      @parser = PdfParser.new("./data/FB 2013 03 13.pdf")
      @parser.process()
    end
    
    it "should create the expected number of calendar days" do
      CalendarDay.all.count.should eq 24
    end
    
    it "should create the expected number of sitting days" do
      SittingDay.all.count.should eq 19
    end
    
    it "should create the expected number of non-sitting days" do
      NonSittingDay.all.count.should eq 5
    end
    
    it "should not replace new content with the older version" do
      sitting_day = CalendarDay.where(:date => Time.parse("2013-03-25 00:00:00Z")).first
      sitting_day.time_blocks.count.should eq 2
      sitting_day.time_blocks[0].business_items.count.should eq 4
      sitting_day.time_blocks[1].business_items.count.should eq 6
    end
  end
end