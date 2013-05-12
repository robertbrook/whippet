require './spec/minitest_helper.rb'
require './parser'

class TimelineTest < MiniTest::Spec
  describe "Parser", "when given the Forthcoming Business for 27th March 2013 PDF as FB-TEST.PDF" do
    before do
      @parser = Parser.new("./spec/FB-TEST.pdf")
      @parser.process
      @parser.output
    end
    
    describe "having passed the PDF to the parser it" do
      it "must return a Parser" do
        @parser.must_be_instance_of Parser
      end
      
      it "must not have an empty output" do
        @parser.output.wont_be_empty
      end
      
      it "must return eight pages" do
        @parser.pages.length.must_equal 8
      end
      
      it "must return 14 dates" do
        @parser.output[:dates].length.must_equal 14
      end
      
      it "must have a first date of 'WEDNESDAY 27 MARCH 2013'" do
        @parser.output[:dates].first[:date].must_equal "WEDNESDAY 27 MARCH 2013"
      end
      
      it "must have a last time of 'Business in Grand Committee at 3.45pm'" do
        @parser.output[:dates].first[:times].last[:time].must_equal "Business in Grand Committee at 3.45pm"
      end
      
      describe "when looking at 'WEDNESDAY 27 MARCH 2013'" do
        before do
          @day = (@parser.output[:dates].select { |date|  date[:date] == 'WEDNESDAY 27 MARCH 2013' }).first
        end
        
        it "must have two times" do
          @day[:times].length.must_equal 2
        end
        
        it "must have a first time of 'Business in the Chamber at 11.00am'" do
          @day[:times].first[:time].must_equal "Business in the Chamber at 11.00am"
        end
        
        it "must have a last time of 'Business in Grand Committee at 3.45pm'" do
          @day[:times].last[:time].must_equal "Business in Grand Committee at 3.45pm"
        end
        
        describe "when looking at 'Business in the Chamber at 11.00am'" do
          before do
            @time = @day[:times].first
          end
          
          it "must have four items" do
            @time[:items].length.must_equal 4
          end
          
          it "must not have any notes" do
            @time[:note].must_be_nil
          end
        end
        
        describe "when looking at 'Business in Grand Committee at 3.45pm'" do
          before do
            @time = @day[:times].last
          end
          
          it "must have no items" do
            @time[:items].length.must_equal 0
          end
          
          it "must have a note" do
            @time[:note].wont_be_empty
          end
          
          it "must have a note with the text 'No business scheduled'" do
            @time[:note].must_equal "No business scheduled"
          end
        end
      end
      
      it "must have a last date of 'FRIDAY 17 MAY 2013'" do
        @parser.output[:dates].last[:date].must_equal "FRIDAY 17 MAY 2013"
      end
    end
  end
end