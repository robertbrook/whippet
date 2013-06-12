require "pdf/reader"
require "nokogiri"
require "mongo_mapper"

require "./models/sitting_day"
require "./lib/pdf_page"

class Parser
  #prepare to ingest a single pdf
  def initialize(target_pdf)
    if db = ENV["MONGOHQ_DEV_URI"]
      MongoMapper.setup({'production' => {'uri' => db}}, 'production')
    else
      env = ENV['RACK_ENV'] || "development"
      MongoMapper.setup({"#{env}" => {'uri' => YAML::load_file("./config/mongo.yml")[env]['uri']}}, env)
    end
    @pdf = PDF::Reader.new(target_pdf)
    @pdf_filename = target_pdf.split("/").last
    @business = []
  end
  
  def pages
    @pdf.pages
  end
  
  def process(debug=false)
    @fin = false
    @provisional = false
    @last_line_was_blank = false
    @in_item = false
    @current_sitting_day = nil
    @current_time_block = nil
    
    pages.each do |page|
      break if @fin
      
      pdf_page = PdfPage.new(page)
      pdf_page.lines.each_with_index do |pdf_page_line, line_no|
        line = pdf_page_line[:plain]
        html = pdf_page_line[:html]
        
        case line
        
        #the end of the useful, the start of the notes section, we can stop now
        when /Information/
          p "ok, ignoring the rest of this" if debug
          @fin = true
          break
        
        when /^\s*PROVISIONAL\s*$/
          p "/sets provisional flag" if debug
          @provisional = true
        
        #a new day
        when /\b([A-Z]{2,}[DAY] \d+ [A-Z]+ \d{4})/
          p "new day detected, starting a new section: #{line}" if debug
          if @current_sitting_day
            @current_sitting_day.save
            @business << @current_sitting_day
          end
          @last_line_was_blank = false
          current_date = $1
          @in_item = false
          
          Time.parse(@pdf.info[:ModDate])
          
          pdf_info = {:filename => @pdf_filename, :page => page.number, :line => line_no, :last_edited => Time.parse(@pdf.info[:ModDate].gsub(/\+\d+'\d+'/, "Z"))}
          @current_sitting_day = SittingDay.create(:date => Date.parse(current_date), :accepted => false, :pdf_info => pdf_info)
          if @provisional
            @current_sitting_day.is_provisional = true
            @current_sitting_day.save
          end
        
        #a new time
        when /^\s*Business/
          p "new time detected, starting a new sub-section: #{line}" if debug
          @last_line_was_blank = false
          @in_item = false
          block = TimeBlock.new
          time_matches = line.match(/at ((\d+)\.(\d\d)(a|p)m)/)
          if time_matches[4] == "p"
            block.time_as_number = (time_matches[2].to_i + 12) * 100 + time_matches[3].to_i
          else
            block.time_as_number = time_matches[2].to_i * 100 + time_matches[3].to_i
          end
          block.title = line.strip
          
          Time.parse(@pdf.info[:ModDate])
          
          pdf_info = {:filename => @pdf_filename, :page => page.number, :line => line_no, :last_edited => Time.parse(@pdf.info[:ModDate].gsub(/\+\d+'\d+'/, "Z"))}
          block.pdf_info = pdf_info
          block.is_provisional = true if @provisional
          @current_time_block = block
          @current_sitting_day.time_blocks << @current_time_block
        
        #a page number
        when /^\s*(\d+)\n/
          page_number = $1
          p "** end of page #{page_number} **" if debug
        
        #a numbered item
        when /^(\d)/
          p "new business item, hello: #{line}" if debug
          @last_line_was_blank = false
          @in_item = true
          # first line of item
          item = BusinessItem.new
          item.description = line.strip
          
          pdf_info = {:filename => @pdf_filename, :page => page.number, :line => line_no, :last_edited => Time.parse(@pdf.info[:ModDate].gsub(/\+\d+'\d+'/, "Z"))}
          item.pdf_info = pdf_info
          @current_time_block.business_items << item
        
        #a blank line
        when /^\n$/
          if @last_line_was_blank and @in_item
            p "A blank following a blank line, resetting the itemflag" if debug
            @in_item = false
          end
          @last_line_was_blank = true
        
        #whole line in square brackets
        when /^\s*\[.*\]\s*$/
          p "Meh, no need to process these #{line}" if debug
          @last_line_was_blank = false
        
        #all the other things
        else
          if @in_item
            @last_line_was_blank = false
            p "...item continuation line..." if debug
            #last line was a business item, treat this as a continuation
            last_item = @current_time_block.business_items.last
            new_desc = "#{last_item.description} #{line.strip}"
            last_item.description = new_desc
            
            p "item text replaced with: #{new_desc}" if debug
          else
            #the last line wasn't blank and we're not in item space - a note!
            if line =~ /^\s+\b[A-Z][a-z]/ and @last_line_was_blank == false
              unless @current_sitting_day.time_blocks.empty?
                if html.include?("<i><b>")
                  p html if debug
                  #not what we first took it for, not sure what do do with it... yet
                else
                  p "notes about the time: #{line}" if debug
                  @current_time_block.note = line.strip
                  @current_time_block.save
                end
              else
                p "notes about the day: #{line}" if debug
                @current_sitting_day.note = line.strip
              end
            else
              @last_line_was_blank = false
              p "Unhandled text: #{line}" if debug
            end
          end
        end
      end
    end
    if @current_sitting_day
      @current_sitting_day.save
      @business << @current_sitting_day
    end
    nil
  end
  
  def output
    @business
  end
end