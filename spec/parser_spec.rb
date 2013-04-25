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

  end

  describe "having run the Parser process and Parser output it" do

  	it "must return an @parser with eight pages" do
  		@parser.process
  		@parser.output
  		@parser.pages.length.must_equal 8
  	end
  end

end

