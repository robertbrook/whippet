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
      @parser.output[:dates][0][:date].must_equal "WEDNESDAY 27 MARCH 2013"
    end

    it "must have a last date of 'FRIDAY 17 MAY 2013'" do
      @parser.output[:dates][-1][:date].must_equal "FRIDAY 17 MAY 2013"
    end

  end

end
