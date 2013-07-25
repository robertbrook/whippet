#encoding: utf-8

require './lib/page_text_markup_receiver'

class PdfPage
  attr_reader :fonts, :lines, :formatted_lines
  
  def initialize(page)
    receiver = PDF::Reader::PageTextMarkupReceiver.new()
    page.walk(receiver)
    @lines = receiver.content.lines.to_a
    @formatted_lines = receiver.markup.lines.to_a
  end
end