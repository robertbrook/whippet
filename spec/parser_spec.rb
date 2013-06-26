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
      
      it "must return output" do
        @parser.output.wont_be_nil
      end
      
    end
    
    describe "when asked to process the document" do
      before do
        @@doc_processed ||= false
        unless @@doc_processed
          SittingDay.delete_all
          @parser.process
          @@doc_processed = true
        end
      end
      
      it "should not duplicate the items" do
        SittingDay.all.count.must_equal(14)
        @parser.process
        SittingDay.all.count.must_equal(14)
      end
      
      it "must find eight pages of content" do
        @parser.pages.length.must_equal 8
      end
      
      it "must create a SittingDay for each date" do
        SittingDay.all.count.must_equal(14)
      end
      
      it "must create all the TimeBlocks" do
        days = SittingDay.all
        blocks = days.map { |x| x.time_blocks }.flatten
        blocks.count.must_equal(23)
      end
      
      it "must create all the BusinessItems" do
        days = SittingDay.all
        blocks = days.map { |x| x.time_blocks }.flatten
        items = blocks.map { |x| x.business_items }.flatten
        items.count.must_equal(43)
      end
      
      describe "the created object for Wednesday 27 March" do
        before do
          @sitting_day = SittingDay.where(:date => Time.parse("2013-03-27 00:00:00Z")).first
        end
        
        it "must not be flagged as provisional" do
          @sitting_day.is_provisional.wont_equal true
        end
        
        it "must have the pdf file name" do
          @sitting_day.pdf_info[:filename].must_equal 'FB-TEST.pdf'
        end
        
        it "must store the pdf last edited datetime" do
          @sitting_day.pdf_info[:last_edited].must_equal Time.parse("D:20130328102303Z")
        end
        
        it "must have the page and line number info" do
          @sitting_day.pdf_info[:page].must_equal(1)
          @sitting_day.pdf_info[:line].must_equal(13)
        end
        
        it "must have two TimeBlocks" do
          @sitting_day.time_blocks.length.must_equal 2
        end
        
        it "must have a first TimeBlock entitled 'Business in the Chamber at 11.00am'" do
          @sitting_day.time_blocks.first.title.must_equal "Business in the Chamber at 11.00am"
          @sitting_day.time_blocks.first.time_as_number.must_equal 1100
          @sitting_day.time_blocks.first.is_provisional.wont_equal true
        end
                
        it "must have a last TimeBlock entitled 'Business in Grand Committee at 3.45pm'" do
          @sitting_day.time_blocks.last.title.must_equal "Business in Grand Committee at 3.45pm"
          @sitting_day.time_blocks.last.time_as_number.must_equal 1545
        end
                
        describe "when looking at 'Business in the Chamber at 11.00am'" do
          before do
            @time = @sitting_day.time_blocks.first
          end
          
          it "must have the page and line number info" do
            @time.pdf_info[:page].must_equal(1)
            @time.pdf_info[:line].must_equal(15)
          end
          
          it "must have four items" do
            @time.business_items.length.must_equal 4
          end
          
          it "must set page and line info for the business items" do
            @time.business_items[2].pdf_info[:page].must_equal(1)
            @time.business_items[2].pdf_info[:line].must_equal(21)
          end
          
          it "must not have any notes" do
            @time.note.must_be_nil
          end
        end
        
        describe "when looking at 'Business in Grand Committee at 3.45pm'" do
          before do
            @time = @sitting_day.time_blocks.last
          end
          
          it "must have the page and line number info" do
            @time.pdf_info[:page].must_equal(1)
            @time.pdf_info[:line].must_equal(29)
          end
          
          it "must have no items" do
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
        
        it "the TimeBlocks should be flagged as provisional" do
          @sitting_day.time_blocks[0].is_provisional.must_equal true
          @sitting_day.time_blocks[1].is_provisional.must_equal true
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
          SittingDay.delete_all
          @parser.process
          @@doc2_processed = true
        end
      end
      
      it "must create the expected number of sitting days" do
        SittingDay.all.count.must_equal 16
      end
      
      it "must cope with business items scheduled for 12 noon" do
        sitting_day = SittingDay.where(:date => Time.parse("2013-05-22 00:00:00Z")).first
        sitting_day.time_blocks[1].time_as_number.must_equal 1200
      end
      
      it "must cope with simple marshalled list notes" do
        sitting_day = SittingDay.where(:date => Time.parse("2013-05-31 00:00:00Z")).first
        sitting_day.note.must_equal "Last day to table amendments for the marshalled list for: Care Bill - Committee Day 1"
      end
      
      it "must cope with multi-line marshalled list notes" do
        sitting_day = SittingDay.where(:date => Time.parse("2013-06-03 00:00:00Z")).first
        sitting_day.note.must_equal "House dinner in the Peers’ Dining Room at 7.30pm; Last day to table amendments for the marshalled list for: Rehabilitation of Offenders Bill - Committee Day 1; Mesothelioma Bill – Committee Day 1"
      end
      
      it "should mark 9 of the sitting days as provisional" do
        sitting_day = SittingDay.where(:is_provisional => true)
        sitting_day.count.must_equal 9
      end
      
      # Should it note the Whitsun adjournment? And if so, how?
    end
  end

  describe "Parser", "when given consecutive Forthcoming Business documents where one overrides the other" do
    before do
      @@parser3 ||= Parser.new("./data/FB 2013 03 13.pdf")
      @@doc3_processed ||= false
      unless @@doc3_processed
        SittingDay.delete_all
        @@parser3.process
        @@parser3 = Parser.new("./data/FB 2013 03 20 r.pdf")
        @@parser3.process
        @@doc3_processed = true
      end
    end
    
    it "should create the expected number of sitting days" do
      SittingDay.all.count.must_equal 24
    end
  end
end