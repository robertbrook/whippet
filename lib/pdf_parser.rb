require "pdf/reader"
require "pdf/reader/markup"
require "nokogiri"
require "active_record"

require "./models/calendar_day"
require "./models/business_item"
require "./models/time_block"
require "./models/speaker_list"

require "logger"

# Log = Logger.new('log_file.log')
Log = Logger.new(STDOUT)
Log.level = Logger::INFO

Log.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime.strftime('%H:%M:%S')}\t#{msg}\n"
end

class PdfParser
  #prepare to ingest a single pdf
  def initialize(target_pdf)
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
      break if @information_section
      
      pdf_page = PDF::Reader::MarkupPage.new(page)
      pdf_page.lines.each_with_index do |line, line_no|
        html = pdf_page.formatted_lines[line_no]
        
        case line.squeeze(" ")
        
        #the end of the useful, the start of the notes section, we can stop now
        when /^\s*Information\s*$/
          # Log.info "start of information section"
          @information_section = true
          break
        
        when /^\s*PROVISIONAL\s*$/
          Log.debug "/sets provisional flag"
          @provisional = true
        
        #a new day
        when /(\b[A-Z]{2,}[DAY]\s+\d+ [A-Z]+ \d{4})/
          Log.debug "new day detected, starting a new section: #{line}"
          process_new_day($1, page, line_no)
        
        #a new time
        when /^\s*Business/
          Log.debug "new time detected, starting a new sub-section: #{line}"
          if @current_sitting_day
            process_new_time_block(line, html, page, line_no)
          end
        
        #a page number
        when /^\s*(\d+)\n?$/
          Log.debug "** end of page #{$1} **"
        
        #a numbered item
        when /^(\d)/
          Log.debug "new business item, hello: #{line}"
          Log.debug "aka #{html}"
          if @current_sitting_day
            process_new_business_item(line, html, page, line_no)
          end
        
        #a blank line
        when /^\s*\n?$/
          process_blank_line(line_no, debug)
        
        #whole line in square brackets
        when /^\s*\[.*\]\s*$/
          Log.debug "Meh, no need to process these #{line}"
          @last_line_was_blank = false if @current_sitting_day
        
        #all the other things
        else
          process_catchall(line, html, line_no, debug)
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
    @information_section = false
    @provisional = false
    @last_line_was_blank = false
    @in_item = false
    @current_sitting_day = nil
    @current_time_block = nil
    @old_day = nil
    @block_position = 0
    @item_position = 0
  end
  
  def fix_description
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
  
  def deref_pdf_info(pdf, att)
    info = pdf.info[att]
    if info.is_a?(PDF::Reader::Reference)
      info = pdf.objects[info]
    end
    info
  end
  
  def set_pdf_info(page, line_no, last_line=nil)
    info = {:filename => @pdf_filename, 
     :page => page.number, 
     :line => line_no+1, 
     :last_edited => Time.parse(deref_pdf_info(@pdf, :ModDate).gsub(/\+\d+'\d+'/, "Z"))}
    if last_line
      info[:last_line] = last_line+1
    end
    info
  end
  
  def init_new_day(line_no)
    if @current_sitting_day
      unless @current_sitting_day.respond_to?(:time_blocks)
        @current_sitting_day = @current_sitting_day.becomes(NonSittingDay)
      else  
        fix_description()
      end
      if @old_day
        change = @current_sitting_day.diff(@old_day)
        unless change.empty?
          append_to_diffs(@current_sitting_day, change)
        end
      end
      @current_sitting_day.save
      @old_day.delete if @old_day
    end
    @last_line_was_blank = false
    @in_item = false
  end
  
  def create_new_sitting_day(current_date, pdf_info)
    @block_position = 0
    @item_position = 0
    date = Date.parse(current_date)
    CalendarDay.new(
      :date => date,
      :accepted => false,
      :meta => ({"pdf_info" => pdf_info}),
      :ident => "CalendarDay_#{date.strftime("%Y-%m-%d")}"
    )
  end
  
  def get_previous_day(current_date)
    parsed_time = Time.parse(current_date).strftime("%Y-%m-%d 00:00:00Z")
    CalendarDay.where(:date => Time.parse(parsed_time)).first
  end
  
  def process_new_day(current_date, page, line_no)
    init_new_day(line_no)
    prev = get_previous_day(current_date)
    pdf_info = set_pdf_info(page, line_no)
    @old_day = nil
    @current_sitting_day = create_new_sitting_day(current_date, pdf_info)
    if @provisional
      @current_sitting_day.is_provisional = true
    end
    if prev
      if Time.parse(prev.meta["pdf_info"]["last_edited"]) < 
          Time.parse(deref_pdf_info(@pdf, :ModDate).gsub(/\+\d+'\d+'/, "Z"))
        #the found version is old, keep ahold of it for the time being
        @old_day = prev
      else
        #the new data is old or a duplicate, ignore it
        @current_sitting_day = nil
      end
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
    block.ident = block.generate_ident()
    
    Time.parse(deref_pdf_info(@pdf, :ModDate))
    
    pdf_info = set_pdf_info(page, line_no)
    block.meta = {"pdf_info" => pdf_info}
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
    item.ident = item.generate_ident()
    
    pdf_info = set_pdf_info(page, line_no, line_no)
    item.meta = {"pdf_info" => pdf_info}
    @current_time_block.business_items << item
  end
  
  def process_blank_line(line_no, debug)
    if @current_sitting_day
      if @last_line_was_blank and @in_item
        Log.debug "A blank following a blank line, resetting the itemflag"
        fix_description()
        @in_item = false
      end
      @last_line_was_blank = true
    end
  end
  
  def process_catchall(line, html, line_no, debug)
    if @current_sitting_day
      if @in_item
        process_continuation_line(line, line_no, debug)
      else
        #the last line wasn't blank and we're not in item space - a note!
        process_notes_and_exceptions(line, html, debug)
      end
    end
  end
  
  def process_continuation_line(line, line_no, debug)
    @last_line_was_blank = false
    Log.debug "...item continuation line..."
    #last line was a business item, treat this as a continuation
    last_item = @current_time_block.business_items.last
    new_desc = "#{last_item.description.rstrip} #{line.strip}"
    last_item.description = new_desc
    last_item.meta["pdf_info"]["last_line"] = line_no+1
    
    Log.debug "item text replaced with: #{new_desc}"
  end
  
  def process_notes_and_exceptions(line, html, debug)
    if html.include?("<b><i>")
      Log.debug "Unhandled markup: #{html}"
      #not what we first took it for, not sure what do do with it... yet
      return
    end
    if @last_line_was_blank == false
      if @current_sitting_day.has_time_blocks?
        Log.debug "notes about the time: #{line}"
        @current_time_block.note = line.strip
        @current_time_block.save
      else
        Log.debug "notes about the day: #{line}"
        store_note(line)
      end
    else
      @last_line_was_blank = false
      if line.strip =~ /(L|l)ast day to table amendments/
        Log.debug "notes about the day (again!): #{line}"
        store_note(line)
      else
        Log.debug "Unhandled text: #{line}"
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
        append_to_diffs(@current_sitting_day, change)
      end
      @old_day.delete
    end
    @current_sitting_day.save
  end
  
  def append_to_diffs(record, change)    
    if record.history.nil?
      record.history = {"diffs" => [change]}
    else
      record.history["diffs"] << change
    end
    
    # if record.ident == "CalendarDay_2013-03-25"
    #   p record.history
    #   p "**"
    # end
  end
end