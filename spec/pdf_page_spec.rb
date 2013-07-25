#encoding: utf-8

require './spec/minitest_helper.rb'
require './lib/pdf_page'

class PdfPageTest < MiniTest::Spec
  describe "PdfPage", "when given the Forthcoming Business for 27th March 2013 PDF as FB-TEST.PDF" do
    before do
      @@pdf ||= PDF::Reader.new("./data/FB-TEST.pdf")
      @pdf = @@pdf
    end
    
    describe "when asked to load page 1" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages.first)
      end
      
      it "should return the expected number of lines" do
        @pdf_page.lines.count.must_equal 31
      end
      
      it "should return both the original plain text and the html markup for each line" do
        @pdf_page.lines[0].must_equal "                   GOVERNMENT WHIPS’ OFFICE\n"
        @pdf_page.formatted_lines[0].must_equal "GOVERNMENT WHIPS’ OFFICE\n"
        
        @pdf_page.lines[3].must_equal "                     FORTHCOMING BUSINESS\n"
        @pdf_page.formatted_lines[3].must_equal "<b>FORTHCOMING BUSINESS</b>\n"
        
        @pdf_page.lines[6].must_equal "                        [Notes about this document are set out at the end]\n"
        @pdf_page.formatted_lines[6].must_equal "[<i>Notes about this document are set out at the end</i>]\n"
        
        @pdf_page.lines[14].must_equal "2.  Draft Legal Aid, Sentencing and Punishment of Offenders Act 2012\n"
        @pdf_page.formatted_lines[14].must_equal "2. Draft Legal Aid, Sentencing and Punishment of Offenders Act 2012\n"
        
        @pdf_page.lines[19].must_equal "    (2 and 3 expected to be debated together)\n"
        @pdf_page.formatted_lines[19].must_equal "(<i>2 and 3 expected to be debated together</i>)\n"
        
        @pdf_page.lines[23].must_equal "Business in Grand Committee at 3.45pm\n"
        @pdf_page.formatted_lines[23].must_equal "<b>Business in Grand Committee at 3.45pm</b>\n"
      end
    end
    
    describe "when asked to load page 3" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages[2])
      end
      
      it "should find the italic text correctly" do
        @pdf_page.formatted_lines[1].must_equal "<i>House dinner in the Peers’ Dining Room at 7.30 p.m.</i>\n"
      end
      
      it "should close the markup tags correctly" do
        @pdf_page.lines[40].must_equal "           [The date and time for the prorogation of Parliament\n"
        @pdf_page.formatted_lines[40].must_equal "[<b><i>The date and time for the prorogation of Parliament</i></b>\n"
      end
    end
    
    describe "when asked to load page 7" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages[6])
      end
      
      it "should cope with the information text"  do
        line = @pdf_page.lines[2]
        line.must_equal "  This document informally advertises the business which the Government anticipates the House will\n"
      end
    end
  end
  
  describe "PdfPage", "when given the Forthcoming Business for 13th March 2013 PDF as FB 2013 03 13.pdf" do
    before do
      @@pdf2 ||= PDF::Reader.new("./data/FB 2013 03 13.pdf")
      @pdf = @@pdf2
    end
    
    describe "when asked to load page 1" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages.first)
      end
      
      it "should return both the original plain text and the html markup for each line" do
        @pdf_page.lines[3].must_equal "                     FORTHCOMING BUSINESS\n"
        @pdf_page.formatted_lines[3].must_equal "<b>FORTHCOMING BUSINESS</b>\n"
        
        @pdf_page.lines[6].must_equal "                        [Notes about this document are set out at the end]\n"
        @pdf_page.formatted_lines[6].must_equal "[<i>Notes about this document are set out at the end</i>]\n"
        
        @pdf_page.lines[13].must_equal "1.  Oral questions (30 minutes)\n"
        @pdf_page.formatted_lines[13].must_equal "1. Oral questions (30 minutes)\n"
        
        @pdf_page.lines[22].must_equal "Business in Grand Committee at 3.45pm\n"
        @pdf_page.formatted_lines[22].must_equal "<b>Business in Grand Committee at 3.45pm</b>\n"
        
        @pdf_page.lines[23].must_equal "    No business scheduled\n"
        @pdf_page.formatted_lines[23].must_equal "No business scheduled\n"
      end
    end
    
    describe "when asked to load page 2" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages[1])
      end
      
      it "should return both the original plain text and the html markup for each line" do
        @pdf_page.lines[1].must_equal "                               The House is expected not to sit\n"
        @pdf_page.formatted_lines[1].must_equal "<i>The House is expected not to sit</i>\n"
        
        @pdf_page.lines[3].must_equal "Last day to table amendments for the marshalled list for:\n"
        @pdf_page.formatted_lines[3].must_equal "Last day to table amendments for the marshalled list for:\n"
        
        @pdf_page.lines[4].must_equal "        Welfare Benefits Up-rating Bill - Report Day 1\n"
        @pdf_page.formatted_lines[4].must_equal "<i>Welfare Benefits Up-rating Bill - Report Day 1</i>\n"
        
        @pdf_page.lines[33].must_equal "     (3, 4 and 5 expected to be debated together)\n"
        @pdf_page.formatted_lines[33].must_equal "(<i>3, 4 and 5 expected to be debated together</i>)\n"
      end
    end
    
    describe "when asked to load page 3" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages[2])
      end
      
      it "should return both the original plain text and the html markup for each line" do
        @pdf_page.lines[8].must_equal "2.  Welfare Benefits Up-rating Bill – Report (Day 1 of 1†) – Baroness Stowell of\n"
        @pdf_page.formatted_lines[8].must_equal "2. Welfare Benefits Up-rating Bill – Report (Day 1 of 1†) – Baroness Stowell of\n"
        
        @pdf_page.lines[35].must_equal "3.  Enterprise and Regulatory Reform Bill – Third Reading – Viscount Younger\n"
        @pdf_page.formatted_lines[35].must_equal "3. Enterprise and Regulatory Reform Bill – Third Reading – Viscount Younger\n"
        
        @pdf_page.lines[36].must_equal "     of Leckie\n"
        @pdf_page.formatted_lines[36].must_equal "of Leckie\n"
      end
    end
    
    describe "when asked to load page 4" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages[3])
      end
      
      it "should return text and html markup" do
        @pdf_page.lines[2].must_equal "Business in the Chamber at 11.00am\n"
        @pdf_page.formatted_lines[2].must_equal "<b>Business in the Chamber at 11.00am</b>\n"
      end
    end
    
    describe "when asked to load page 5" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages[4])
      end
      
      it "should return the plain text and html markup for each line" do
        @pdf_page.lines[12].must_equal "     No business yet scheduled\n"
        @pdf_page.formatted_lines[12].must_equal "No business yet scheduled\n"
      end
    end
    
    describe "when asked to load page 6" do
      before do
        @pdf_page = PdfPage.new(@pdf.pages[5])
      end
      
      it "should return both the original plain text and the html markup for each line" do
        @pdf_page.lines[1].must_equal "                       House dinner in the Peers’ Dining Room at 7.30pm\n"
        @pdf_page.formatted_lines[1].must_equal "<i>House dinner in the Peers’ Dining Room at 7.30pm</i>\n"
        
        @pdf_page.lines[6].must_equal "3.  Succession to the Crown Bill – Third Reading – Lord Wallace of Tankerness\n"
        @pdf_page.formatted_lines[6].must_equal  "3. Succession to the Crown Bill – Third Reading – Lord Wallace of Tankerness\n"
        
        @pdf_page.lines[15].must_equal "2.  Further business will be scheduled\n"
        @pdf_page.formatted_lines[15].must_equal  "2. <i>Further business will be scheduled</i>\n"
      end
    end
  end
end