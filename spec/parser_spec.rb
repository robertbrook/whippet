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
    end
    
    describe "when asked to process the document" do
      before do
        SittingDay.delete_all
        @parser.process
      end
      
      it "must find eight pages of content" do
        @parser.pages.length.must_equal 8
      end
      
      it "must create a SittingDay for each date" do
        SittingDay.all.count.must_equal(14)
      end
      
      it "must create all the TimeBlocks" do
        days = SittingDay.all
        blocks = days.map { |x| x.time_blocks }
        blocks.flatten.count.must_equal(23)
      end
      
      it "must create all the BusinessItems" do
        #BusinessItem.all.count.must_equal(43)
      end
      
      describe "the created object for Wednesday 27 March" do
        before do
          SittingDay.delete_all
          @parser.process
          @sitting_day = SittingDay.where(:date => Time.parse("2013-03-27 00:00:00 UTC")).first
        end
        
        it "must not be flagged as provisional" do
          @sitting_day.is_provisional.wont_equal true
        end
        
        it "must have the pdf file name" do
          @sitting_day.pdf_file.must_equal 'FB-TEST.pdf'
        end
        
        it "must have the page and line number info" do
          @sitting_day.pdf_page.must_equal("1")
          @sitting_day.pdf_page_line.must_equal(13)
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
            @time.pdf_page.must_equal("1")
            @time.pdf_page_line.must_equal(15)
          end
          
          it "must have four items" do
            @time.business_items.length.must_equal 4
          end
          
          it "must set page and line info for the business items" do
            @time.business_items[2].pdf_page.must_equal("1")
            @time.business_items[2].pdf_page_line.must_equal(21)
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
            @time.pdf_page_line.must_equal(29)
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