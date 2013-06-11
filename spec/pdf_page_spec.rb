require './spec/minitest_helper.rb'
require './lib/pdf_page'

class PdfPageTest < MiniTest::Spec
  describe "PdfPage", "when given the Forthcoming Business for 27th March 2013 PDF as FB-TEST.PDF" do
    before do
      @pdf = PDF::Reader.new("./data/FB-TEST.pdf")
    end
    
    describe "when asked to load page 1" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages.first)
      end
      
      it "should correctly identify 5 different font variations" do
        fonts = @pdf_page.fonts
        fonts.length.must_equal 5
        fonts[:F1][:family].must_equal "Book Antiqua"
        fonts[:F1][:bold].must_equal false
        fonts[:F1][:italic].must_equal false
        
        fonts[:F2][:bold].must_equal false
        fonts[:F2][:italic].must_equal false
        
        fonts[:F3][:bold].must_equal true
        fonts[:F3][:italic].must_equal false
        
        fonts[:F4][:bold].must_equal false
        fonts[:F4][:italic].must_equal true
        
        fonts[:F5][:bold].must_equal true
        fonts[:F5][:italic].must_equal true
      end
      
      it "should return the expected number of lines" do
        @pdf_page.lines.count.must_equal @pdf.pages.first.text.lines.count
        @pdf_page.lines.count.must_equal 42
      end
      
      it "should return both the original plain text and the html markup for each line" do
        line = @pdf_page.lines[4]
        line[:plain].must_equal "                 FORTHCOMING BUSINESS\n"
        line[:html].must_equal "<b>FORTHCOMING BUSINESS</b>"
        
        line = @pdf_page.lines[8]
        line[:plain].must_equal "                   [Notes about this document are set out at the end]\n"
        line[:html].must_equal "[<i>Notes about this document are set out at the end</i>]"
        
        line = @pdf_page.lines[29]
        line[:plain].must_equal "Business in Grand Committee at 3.45pm\n"
        line[:html].must_equal "<b>Business in Grand Committee at 3.45pm</b>"
        
        line = @pdf_page.lines[18]
        line[:plain].must_equal "2.  Draft Legal Aid, Sentencing and Punishment of Offenders Act 2012\n"
        line[:html].must_equal "2.  Draft Legal Aid, Sentencing and Punishment of Offenders Act 2012"
      end
    end
    
    describe "when asked to load page 2" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages[1])
      end
      
      it "should find 5 fonts" do
        @pdf_page.fonts.length.must_equal 5
      end
      
      it "should find a font labelled F6 for page 2" do
        @pdf_page.fonts[:F6][:family].must_equal "Book Antiqua"
      end
    end
    
    describe "when asked to load page 3" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages[2])
      end
      
      it "should find 6 fonts" do
        @pdf_page.fonts.count.must_equal 6
      end
      
      it "should close the markup tags correctly" do
        line = @pdf_page.lines[50]
        line[:html].must_equal "[<i><b>The date and time for the prorogation of Parliament</b></i>"
      end
    end
    
    describe "when asked to load page 4" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages[3])
      end
      
      it "should find 4 fonts" do
        @pdf_page.fonts.count.must_equal 4
      end
    end
  end
end