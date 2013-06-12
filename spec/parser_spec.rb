require './spec/minitest_helper.rb'
require './lib/parser'

class ParserTest < MiniTest::Spec
  describe "Parser", "when given the Forthcoming Business for 27th March 2013 PDF as FB-TEST.PDF" do
    before do
      @parser = Parser.new("./data/FB-TEST.pdf")
      SittingDay.delete_all
    end
    
    describe "in general" do
      it "must return a Parser" do
        @parser.must_be_instance_of Parser
      end
      
      it "must find eight pages of content" do
        @parser.pages.length.must_equal 8
        @parser.process
      end
    end
    
    describe "when asked to process the document" do      
      it "must create a SittingDay for each date" do
        sitting_day = SittingDay.new
        SittingDay.expects(:create).times(14).returns(sitting_day)
        @parser.process
      end
      
      it "must create all the TimeBlocks" do
        block = TimeBlock.new
        TimeBlock.expects(:new).times(23).returns(block)
        block.expects(:title=).times(23)
        block.expects(:time_as_number=).times(23)
        @parser.process
      end
      
      it "must create all the BusinessItems" do
        item = BusinessItem.new
        BusinessItem.expects(:new).times(43).returns(item)
        item.expects(:description=).at_least(43) #could be more - corrections
        @parser.process
      end
      
      describe "the created object for Wednesday 27 March" do
        before do
          SittingDay.delete_all
          @parser.process
          @sitting_day = SittingDay.where(:date => Time.parse("2013-03-27 00:00:00 UTC")).first
        end
        
        it "must have the pdf file name" do
          @sitting_day.pdf_file.must_equal 'FB-TEST.pdf'
        end
        
        it "must have the page and line number info" do
          @sitting_day.pdf_page.must_equal("1")
          @sitting_day.pdf_line.must_equal(13)
        end
        
        it "must have two TimeBlocks" do
          @sitting_day.time_blocks.length.must_equal 2
        end
        
        it "must have a first TimeBlock entitled 'Business in the Chamber at 11.00am'" do
          @sitting_day.time_blocks.first.title.must_equal "Business in the Chamber at 11.00am"
          @sitting_day.time_blocks.first.time_as_number.must_equal 1100
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
            @time.pdf_page.must_equal("1")
            @time.pdf_line.must_equal(15)
          end
          
          it "must have four items" do
            @time.business_items.length.must_equal 4
          end
          
          it "must set page and line info for the business items" do
            @time.business_items[2].pdf_page.must_equal("1")
            @time.business_items[2].pdf_line.must_equal(21)
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
            @time.pdf_page.must_equal("1")
            @time.pdf_line.must_equal(29)
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
          SittingDay.delete_all
          @parser.process
          @sitting_day = SittingDay.where(:date => Time.parse("2013-5-8 00:00:00 UTC")).first
        end
        
        it "must the flagged as provisional" do
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
end