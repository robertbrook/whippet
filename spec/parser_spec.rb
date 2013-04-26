require 'minitest/autorun'
require './parser'

describe Parser, "when given the Forthcoming Business for 27th March 2013 PDF as FB-TEST.PDF" do
  before do
    @parser = Parser.new("FB-TEST.pdf")
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

    describe "when looking at 'WEDNESDAY 27 MARCH 2013'" do

      it "must have two times" do
        @parser.output[:dates].first[:times].length.must_equal 2
      end

      it "must have a first time of 'Business in the Chamber at 11.00am'" do
        @parser.output[:dates].first[:times].first[:time].must_equal "Business in the Chamber at 11.00am"
      end

      describe "when looking at 'Business in the Chamber at 11.00am'" do

        it "must have four items" do
          pp @parser.output[:dates].first[:times].first[:items].length.must_equal 4
        end

      end

      it "must have a last time of 'Business in Grand Committee at 3.45pm'" do
        @parser.output[:dates].first[:times].last[:time].must_equal "Business in Grand Committee at 3.45pm"
      end

      describe "when looking at 'Business in Grand Committee at 3.45pm'" do

        it "must have one item"

        it "must have an item with the text 'No business scheduled'"

      end

    end

    it "must have a last date of 'FRIDAY 17 MAY 2013'" do
      @parser.output[:dates].last[:date].must_equal "FRIDAY 17 MAY 2013"
    end

  end

end



