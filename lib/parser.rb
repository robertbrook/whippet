require "pdf/reader"
require "nokogiri"
require "mongo_mapper"

require "./models/calendar_day"
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
    @old_day = nil
    @block_position = 0
    @item_position = 0
    html = ""
    
    pages.each do |page|
      break if @fin
      
      pdf_page = PdfPage.new(page)
      pdf_page.lines.each_with_index do |line, line_no|
        html = pdf_page.formatted_lines[line_no]
        
        case line.squeeze(" ")
        
        #the end of the useful, the start of the notes section, we can stop now
        when /^\s*Information\s*$/
          p "ok, ignoring the rest of this" if debug
          @fin = true
          break
        
        when /^\s*PROVISIONAL\s*$/
          p "/sets provisional flag" if debug
          @provisional = true
        
        #a new day
        when /(\b[A-Z]{2,}[DAY]\s+\d+ [A-Z]+ \d{4})/
          p "new day detected, starting a new section: #{line}" if debug
          current_date = $1
          if @current_sitting_day
            unless @current_sitting_day.respond_to?(:time_blocks)
              @current_sitting_day = @current_sitting_day.becomes(NonSittingDay)
            else  
              if @current_sitting_day.time_blocks.last and @current_sitting_day.time_blocks.last.business_items.count > 0
                item = @current_sitting_day.time_blocks.last.business_items.last
                item.description = item.description.rstrip
              end
            end
            if @old_day
              change = @current_sitting_day.diff(@old_day)
              unless change.empty?
                @current_sitting_day.diffs << change
              end
            end
            @current_sitting_day.save
            @business << @current_sitting_day
          end
          @last_line_was_blank = false
          @in_item = false
          
          parsed_time = Time.parse(current_date).strftime("%Y-%m-%d 00:00:00Z")
          prev = CalendarDay.where(:date => Time.parse(parsed_time)).first
          @old_day = nil
          if prev
            if prev.pdf_info[:last_edited] < Time.parse(@pdf.info[:ModDate].gsub(/\+\d+'\d+'/, "Z"))
              #the found version is old, delete it and allow the new info to replace it
              @old_day = prev.dup
              prev.delete
              pdf_info = {:filename => @pdf_filename, :page => page.number, :line => line_no, :last_edited => Time.parse(@pdf.info[:ModDate].gsub(/\+\d+'\d+'/, "Z"))}
              @current_sitting_day = CalendarDay.new(:date => Date.parse(current_date), :accepted => false, :pdf_info => pdf_info)
              @block_position = 0
              @item_position = 0
            else
              #the new data is old or a duplicate, ignore it
              @current_sitting_day = nil
            end
          else
            pdf_info = {:filename => @pdf_filename, :page => page.number, :line => line_no, :last_edited => Time.parse(@pdf.info[:ModDate].gsub(/\+\d+'\d+'/, "Z"))}
            @current_sitting_day = CalendarDay.new(:date => Date.parse(current_date), :accepted => false, :pdf_info => pdf_info)
            @block_position = 0
            @item_position = 0
          end
          
          if @provisional and @current_sitting_day
            @current_sitting_day.is_provisional = true
          end
        
        #a new time
        when /^\s*Business/
          p "new time detected, starting a new sub-section: #{line}" if debug
          p "aka #{html}" if debug
          if @current_sitting_day
            @current_sitting_day = @current_sitting_day.becomes(SittingDay) unless @current_sitting_day.is_a?(SittingDay)
            if @current_sitting_day.time_blocks.last and @current_sitting_day.time_blocks.last.business_items.count > 0
              item = @current_sitting_day.time_blocks.last.business_items.last
              item.description = item.description.rstrip
            end
            @last_line_was_blank = false
            @in_item = false
            @block_position +=1
            @item_position = 0
            block = TimeBlock.new
            block.position = @block_position
            time_matches = line.match(/at ((\d+)(?:\.(\d\d))?(?:(a|p)m| (noon)))/)
            if time_matches[4] == "p"
              block.time_as_number = (time_matches[2].to_i + 12) * 100 + time_matches[3].to_i
            elsif time_matches[5] == "noon"
              block.time_as_number = (time_matches[2].to_i) * 100
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
          end
        
        #a page number
        when /^\s*(\d+)\n?$/
          page_number = $1
          p "** end of page #{page_number} **" if debug
        
        #a numbered item
        when /^(\d)/
          p "new business item, hello: #{line}" if debug
          p "aka #{html}" if debug
          if @current_sitting_day
            @last_line_was_blank = false
            @in_item = true
            # first line of item
            @item_position +=1
            item = BusinessItem.new
            item.position = @item_position
            item.description = line.strip
            
            pdf_info = {:filename => @pdf_filename, :page => page.number, :line => line_no, :last_edited => Time.parse(@pdf.info[:ModDate].gsub(/\+\d+'\d+'/, "Z"))}
            item.pdf_info = pdf_info
            @current_time_block.business_items << item
          end
        
        #a blank line
        when /^\s*\n?$/
          if @current_sitting_day
            if @last_line_was_blank and @in_item
              p "A blank following a blank line, resetting the itemflag" if debug
              if @current_sitting_day.time_blocks.last and @current_sitting_day.time_blocks.last.business_items.count > 0
                item = @current_sitting_day.time_blocks.last.business_items.last
                item.description = item.description.rstrip
              end
              @in_item = false
            end
            @last_line_was_blank = true
          end
        
        #whole line in square brackets
        when /^\s*\[.*\]\s*$/
          p "Meh, no need to process these #{line}" if debug
          @last_line_was_blank = false if @current_sitting_day
        
        #all the other things
        else
          if @current_sitting_day
            if @in_item
              @last_line_was_blank = false
              p "...item continuation line..." if debug
              #last line was a business item, treat this as a continuation
              last_item = @current_time_block.business_items.last
              new_desc = "#{last_item.description.rstrip} #{line.strip}"
              last_item.description = new_desc
              
              p "item text replaced with: #{new_desc}" if debug
            else
              #the last line wasn't blank and we're not in item space - a note!
              if line =~ /^\s+\b[A-Z][a-z]/ and (@last_line_was_blank == false or line =~ /^\s+No business yet scheduled/)
                if @current_sitting_day.respond_to?(:time_blocks) and @current_sitting_day.time_blocks.count > 0
                  if html.include?("<b><i>")
                    p html if debug
                    #not what we first took it for, not sure what do do with it... yet
                  else
                    p "notes about the time: #{line}" if debug
                    @current_time_block.note = line.strip
                    @current_time_block.save
                  end
                else
                  p "notes about the day: #{line}" if debug
                  if @current_sitting_day.note
                    if @current_sitting_day.note[-1] == ":"
                      @current_sitting_day.note += " #{line.strip}"
                    else
                      @current_sitting_day.note += "; #{line.strip}"
                    end
                  else
                    @current_sitting_day.note = line.strip
                  end
                end
              else
                @last_line_was_blank = false
                if line.strip =~ /(L|l)ast day to table amendments/
                  p "notes about the day (again!): #{line}" if debug
                  if @current_sitting_day.note
                    if @current_sitting_day.note[-1] == ":"
                      @current_sitting_day.note += " #{line.strip}"
                    else
                      @current_sitting_day.note += "; #{line.strip}"
                    end
                  else
                    @current_sitting_day.note = line.strip
                  end
                else                
                  p "Unhandled text: #{line}" if debug
                end
              end
            end
          end
        end
      end
    end
    if @current_sitting_day
      @current_sitting_day = @current_sitting_day.becomes(NonSittingDay) unless @current_sitting_day.respond_to?(:time_blocks)
      if @old_day
        change = @current_sitting_day.diff(@old_day)
        unless change.empty?
          @current_sitting_day.diffs << change
        end
      end
      @current_sitting_day.save
      @business << @current_sitting_day
    end
    nil
  end
  
  def output
    @business
  end
end