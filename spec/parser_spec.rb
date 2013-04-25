require 'minitest/spec'
require 'minitest/autorun'
require './parser'

describe Parser do
	before do
    @parser = Parser.new
  end
  
  describe "when fired up" do
    it "must respond positively" do
      @parser.reply.must_not_equal ""
    end
  end

end
