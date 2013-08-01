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
  end
  
  def pages
    @pdf.pages
  end
  
  def process(debug=false)
    init_process()
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
          process_new_day($1, page, line_no)
        
        #a new time
        when /^\s*Business/
          p "new time detected, starting a new sub-section: #{line}" if debug
          if @current_sitting_day
            process_new_time_block(line, html, page, line_no)
          end
        
        #a page number
        when /^\s*(\d+)\n?$/
          p "** end of page #{$1} **" if debug
        
        #a numbered item
        when /^(\d)/
          if debug
            p "new business item, hello: #{line}"
            p "aka #{html}" if debug
          end
          if @current_sitting_day
            process_new_business_item(line, html, page, line_no)
          end
        
        #a blank line
        when /^\s*\n?$/
          process_blank_line(debug)
        
        #whole line in square brackets
        when /^\s*\[.*\]\s*$/
          p "Meh, no need to process these #{line}" if debug
          @last_line_was_blank = false if @current_sitting_day
        
        #all the other things
        else
          process_catchall(line, html, debug)
        end
      end
    end
    
    if @current_sitting_day
      tidy_up()
    end
    nil
  end
  
  
  private
  
  def init_process
    @fin = false
    @provisional = false
    @last_line_was_blank = false
    @in_item = false
    @current_sitting_day = nil
    @current_time_block = nil
    @old_day = nil
    @block_position = 0
    @item_position = 0
  end
  
  def fix_description()
    if @current_sitting_day.time_blocks.last and @current_sitting_day.time_blocks.last.business_items.count > 0
      item = @current_sitting_day.time_blocks.last.business_items.last
      item.description = item.description.rstrip
    end
  end
  
  def store_note(line)
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
  
  def set_pdf_info(page, line_no)
    {:filename => @pdf_filename, 
     :page => page.number, 
     :line => line_no, 
     :last_edited => Time.parse(@pdf.info[:ModDate].gsub(/\+\d+'\d+'/, "Z"))}
  end
  
  def process_new_day(current_date, page, line_no)
    if @current_sitting_day
      unless @current_sitting_day.respond_to?(:time_blocks)
        @current_sitting_day = @current_sitting_day.becomes(NonSittingDay)
      else  
        fix_description()
      end
      if @old_day
        change = @current_sitting_day.diff(@old_day)
        unless change.empty?
          @current_sitting_day.diffs << change
        end
      end
      @current_sitting_day.save
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
        pdf_info = set_pdf_info(page, line_no)
        @current_sitting_day = CalendarDay.new(:date => Date.parse(current_date), :accepted => false, :pdf_info => pdf_info)
        @block_position = 0
        @item_position = 0
      else
        #the new data is old or a duplicate, ignore it
        @current_sitting_day = nil
      end
    else
      pdf_info = set_pdf_info(page, line_no)
      @current_sitting_day = CalendarDay.new(:date => Date.parse(current_date), :accepted => false, :pdf_info => pdf_info)
      @block_position = 0
      @item_position = 0
    end
    
    if @provisional and @current_sitting_day
      @current_sitting_day.is_provisional = true
    end
  end
  
  def reset_time_block_vars
    @last_line_was_blank = false
    @in_item = false
    @block_position +=1
    @item_position = 0
  end
  
  def parse_heading_time(input)
    matches = input.match(/at ((\d+)(?:\.(\d\d))?(?:(a|p)m| (noon)))/)
    if matches[5] == "noon"
      return (matches[2].to_i) * 100
    end
    
    time = matches[2].to_i * 100 + matches[3].to_i
    if matches[4] == "p"
      time += 1200
    end
    time
  end
  
  def process_new_time_block(line, html, page, line_no)
    unless @current_sitting_day.is_a?(SittingDay)
      @current_sitting_day = @current_sitting_day.becomes(SittingDay)
    end
    fix_description()
    reset_time_block_vars()
    block = TimeBlock.new
    block.position = @block_position
    block.time_as_number = parse_heading_time(line)
    block.title = line.strip
    
    Time.parse(@pdf.info[:ModDate])
    
    pdf_info = set_pdf_info(page, line_no)
    block.pdf_info = pdf_info
    block.is_provisional = true if @provisional
    @current_time_block = block
    @current_sitting_day.time_blocks << @current_time_block
  end
  
  def process_new_business_item(line, html, page, line_no)    
    @last_line_was_blank = false
    @in_item = true
    # first line of item
    @item_position +=1
    item = BusinessItem.new
    item.position = @item_position
    item.description = line.strip
    
    pdf_info = set_pdf_info(page, line_no)
    item.pdf_info = pdf_info
    @current_time_block.business_items << item
  end
  
  def process_blank_line(debug)
    if @current_sitting_day
      if @last_line_was_blank and @in_item
        p "A blank following a blank line, resetting the itemflag" if debug
        fix_description()
        @in_item = false
      end
      @last_line_was_blank = true
    end
  end
  
  def process_catchall(line, html, debug)
    if @current_sitting_day
      if @in_item
        process_continuation_line(line, debug)
      else
        #the last line wasn't blank and we're not in item space - a note!
        process_notes_and_exceptions(line, html, debug)
      end
    end
  end
  
  def process_continuation_line(line, debug)
    @last_line_was_blank = false
    p "...item continuation line..." if debug
    #last line was a business item, treat this as a continuation
    last_item = @current_time_block.business_items.last
    new_desc = "#{last_item.description.rstrip} #{line.strip}"
    last_item.description = new_desc
    
    p "item text replaced with: #{new_desc}" if debug
  end
  
  def process_notes_and_exceptions(line, html, debug)
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
        store_note(line)
      end
    else
      @last_line_was_blank = false
      if line.strip =~ /(L|l)ast day to table amendments/
        p "notes about the day (again!): #{line}" if debug
        store_note(line)
      else                
        p "Unhandled text: #{line}" if debug
      end
    end
  end
  
  def tidy_up    
    unless @current_sitting_day.respond_to?(:time_blocks)
      @current_sitting_day = @current_sitting_day.becomes(NonSittingDay)
    end
    if @old_day
      change = @current_sitting_day.diff(@old_day)
      unless change.empty?
        @current_sitting_day.diffs << change
      end
    end
    @current_sitting_day.save
  end
end