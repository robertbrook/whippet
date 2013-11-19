#encoding: utf-8

require './spec/rspec_helper.rb'
require 'pdf/reader/markup'

describe "PdfReaderMarkup" do
  context "when given the Forthcoming Business for 27th March 2013 PDF as FB-TEST.PDF" do
    before(:all) do
      @pdf = PDF::Reader.new("./data/FB-TEST.pdf")
    end
    
    context "when asked to load page 1" do
      before(:all) do
        @pdf_page = PDF::Reader::MarkupPage.new(@pdf.pages.first)
      end
      
      it "should return the expected number of lines" do
        @pdf_page.lines.count.should eq 32
      end
      
      it "should return both the original plain text and the html markup for each line" do
        @pdf_page.lines[0].should eq "                   GOVERNMENT WHIPS’ OFFICE\n"
        @pdf_page.formatted_lines[0].should eq "GOVERNMENT WHIPS’ OFFICE\n"
        
        @pdf_page.lines[3].should eq "                     FORTHCOMING BUSINESS\n"
        @pdf_page.formatted_lines[3].should eq "<b>FORTHCOMING BUSINESS</b>\n"
        
        @pdf_page.lines[6].should eq "                        [Notes about this document are set out at the end]\n"
        @pdf_page.formatted_lines[6].should eq "[<i>Notes about this document are set out at the end</i>]\n"
        
        @pdf_page.lines[14].should eq "2.  Draft Legal Aid, Sentencing and Punishment of Offenders Act 2012\n"
        @pdf_page.formatted_lines[14].should eq "2. Draft Legal Aid, Sentencing and Punishment of Offenders Act 2012\n"
        
        @pdf_page.lines[19].should eq "    (2 and 3 expected to be debated together)\n"
        @pdf_page.formatted_lines[19].should eq "(<i>2 and 3 expected to be debated together</i>)\n"
        
        @pdf_page.lines[23].should eq "Business in Grand Committee at 3.45pm\n"
        @pdf_page.formatted_lines[23].should eq "<b>Business in Grand Committee at 3.45pm</b>\n"
      end
    end
    
    context "when asked to load page 3" do
      before(:all) do
        @pdf_page = PDF::Reader::MarkupPage.new(@pdf.pages[2])
      end
      
      it "should find the italic text correctly" do
        @pdf_page.formatted_lines[1].should eq "<i>House dinner in the Peers’ Dining Room at 7.30 p.m.</i>\n"
      end
      
      it "should close the markup tags correctly" do
        @pdf_page.lines[40].should eq "           [The date and time for the prorogation of Parliament\n"
        @pdf_page.formatted_lines[40].should eq "[<b><i>The date and time for the prorogation of Parliament</i></b>\n"
      end
    end
    
    context "when asked to load page 7" do
      before(:all) do
        @pdf_page = PDF::Reader::MarkupPage.new(@pdf.pages[6])
      end
      
      it "should cope with the information text"  do
        line = @pdf_page.lines[3]
        line.should eq "  This document informally advertises the business which the Government anticipates the House will\n"
      end
    end
  end
  
  context "when given the Forthcoming Business for 13th March 2013 PDF as FB 2013 03 13.pdf" do
    before(:all) do
      @pdf = PDF::Reader.new("./data/FB 2013 03 13.pdf")
    end
    
    context "when asked to load page 1" do
      before(:all) do
        @pdf_page = PDF::Reader::MarkupPage.new(@pdf.pages.first)
      end
      
      it "should return both the original plain text and the html markup for each line" do
        @pdf_page.lines[3].should eq "                     FORTHCOMING BUSINESS\n"
        @pdf_page.formatted_lines[3].should eq "<b>FORTHCOMING BUSINESS</b>\n"
        
        @pdf_page.lines[6].should eq "                        [Notes about this document are set out at the end]\n"
        @pdf_page.formatted_lines[6].should eq "[<i>Notes about this document are set out at the end</i>]\n"
        
        @pdf_page.lines[13].should eq "1.  Oral questions (30 minutes)\n"
        @pdf_page.formatted_lines[13].should eq "1. Oral questions (30 minutes)\n"
        
        @pdf_page.lines[22].should eq "Business in Grand Committee at 3.45pm\n"
        @pdf_page.formatted_lines[22].should eq "<b>Business in Grand Committee at 3.45pm</b>\n"
        
        @pdf_page.lines[23].should eq "    No business scheduled\n"
        @pdf_page.formatted_lines[23].should eq "No business scheduled\n"
      end
    end
    
    context "when asked to load page 2" do
      before(:all) do
        @pdf_page = PDF::Reader::MarkupPage.new(@pdf.pages[1])
      end
      
      it "should return both the original plain text and the html markup for each line" do
        @pdf_page.lines[1].should eq "                               The House is expected not to sit\n"
        @pdf_page.formatted_lines[1].should eq "<i>The House is expected not to sit</i>\n"
        
        @pdf_page.lines[3].should eq "Last day to table amendments for the marshalled list for:\n"
        @pdf_page.formatted_lines[3].should eq "Last day to table amendments for the marshalled list for:\n"
        
        @pdf_page.lines[4].should eq "        Welfare Benefits Up-rating Bill - Report Day 1\n"
        @pdf_page.formatted_lines[4].should eq "<i>Welfare Benefits Up-rating Bill - Report Day 1</i>\n"
        
        @pdf_page.lines[33].should eq "     (3, 4 and 5 expected to be debated together)\n"
        @pdf_page.formatted_lines[33].should eq "(<i>3, 4 and 5 expected to be debated together</i>)\n"
      end
    end
    
    context "when asked to load page 3" do
      before(:all) do
        @pdf_page = PDF::Reader::MarkupPage.new(@pdf.pages[2])
      end
      
      it "should return both the original plain text and the html markup for each line" do
        @pdf_page.lines[8].should eq "2.  Welfare Benefits Up-rating Bill – Report (Day 1 of 1†) – Baroness Stowell of\n"
        @pdf_page.formatted_lines[8].should eq "2. Welfare Benefits Up-rating Bill – Report (Day 1 of 1†) – Baroness Stowell of\n"
        
        @pdf_page.lines[35].should eq "3.  Enterprise and Regulatory Reform Bill – Third Reading – Viscount Younger\n"
        @pdf_page.formatted_lines[35].should eq "3. Enterprise and Regulatory Reform Bill – Third Reading – Viscount Younger\n"
        
        @pdf_page.lines[36].should eq "     of Leckie\n"
        @pdf_page.formatted_lines[36].should eq "of Leckie\n"
      end
    end
    
    context "when asked to load page 4" do
      before(:all) do
        @pdf_page = PDF::Reader::MarkupPage.new(@pdf.pages[3])
      end
      
      it "should return text and html markup" do
        @pdf_page.lines[2].should eq "Business in the Chamber at 11.00am\n"
        @pdf_page.formatted_lines[2].should eq "<b>Business in the Chamber at 11.00am</b>\n"
      end
    end
    
    context "when asked to load page 5" do
      before(:all) do
        @pdf_page = PDF::Reader::MarkupPage.new(@pdf.pages[4])
      end
      
      it "should return the plain text and html markup for each line" do
        @pdf_page.lines[12].should eq "     No business yet scheduled\n"
        @pdf_page.formatted_lines[12].should eq "No business yet scheduled\n"
      end
    end
    
    context "when asked to load page 6" do
      before(:all) do
        @pdf_page = PDF::Reader::MarkupPage.new(@pdf.pages[5])
      end
      
      it "should return both the original plain text and the html markup for each line" do
        @pdf_page.lines[1].should eq "                       House dinner in the Peers’ Dining Room at 7.30pm\n"
        @pdf_page.formatted_lines[1].should eq "<i>House dinner in the Peers’ Dining Room at 7.30pm</i>\n"
        
        @pdf_page.lines[6].should eq "3.  Succession to the Crown Bill – Third Reading – Lord Wallace of Tankerness\n"
        @pdf_page.formatted_lines[6].should eq  "3. Succession to the Crown Bill – Third Reading – Lord Wallace of Tankerness\n"
        
        @pdf_page.lines[15].should eq "2.  Further business will be scheduled\n"
        @pdf_page.formatted_lines[15].should eq  "2. <i>Further business will be scheduled</i>\n"
      end
    end
  end
end