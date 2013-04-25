require 'minitest/spec'
require 'minitest/autorun'
require './parser'

describe Parser do
  before do
    @parser = Parser.new
  end

  describe "when fired up" do
    it "must respond positively" do
      @parser.mytext.must_equal ""
    end
  end

  describe "process" do
  end

  describe "output" do
  end

end
