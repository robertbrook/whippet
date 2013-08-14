require "mongo_mapper"
require "./lib/mm_monkeypatch"

class CalendarDay
  include MongoMapper::Document
  
  key :date, Date
  key :note, String
  key :accepted, Boolean
  key :is_provisional, Boolean
  key :diffs, Array
  key :pdf_info, Hash
  
  def has_time_blocks?
    return true if respond_to?(:time_blocks) and time_blocks.count > 0
    false
  end
  
  def becomes(klass)
    became = klass.new
    self.instance_variables.each do |var|
      became.instance_variable_set("#{var}", self.instance_variable_get(var))
    end
    became._type = klass.name
    became
  end
  
  def diff(other)
    change = {}
    unless other.is_a?(CalendarDay)
      raise "Unable to compare #{self.class} to #{other.class}"
    end
    
    #the easy bit - fixed simple values
    comp_note = note.nil? ? "" : note
    other_note = other.note.nil? ? "" : other.note
    change[:note] = other_note if note != other.note
    change[:_type] = other._type if _type != other._type
    change[:accepted] = other.accepted if accepted != other.accepted
    change[:is_provisional] = other.is_provisional if is_provisional != other.is_provisional
    
    #analyse the time_blocks
    if self.has_time_blocks? or other.has_time_blocks?
      blocks = []
      current_block_headings = self.has_time_blocks? ? time_blocks.map { |x| x.title } : []
      previous_block_headings = other.has_time_blocks? ? other.time_blocks.map { |x| x.title } : []
      
      #loop through headings in the current block
      current_block_headings.each do |heading|
        #warning: assumes that the heading is unique
        current_block = self.has_time_blocks? ? time_blocks.select { |x| x.title == heading }.first : {}
        previous_block = other.has_time_blocks? ? other.time_blocks.select { |x| x.title == heading }.first : {}
        if heading_in_list?(heading, previous_block_headings)
          #pre-existing thing, compare the differences...
          block = compare_timeblock_with_previous_version(current_block, previous_block)
          
          #...and only store data that's changed
          unless block.empty?
            block[:title] = current_block.title
            block[:change_type] = "modified"
            block[:pdf_info] = previous_block.pdf_info
            blocks << block
          end
        else
          #a new thing, just need to note its arrival
          blocks << {:title => current_block.title, :change_type => "new"}
        end
      end
      
      #look for headings only exist in the previous block
      deleted_headings = previous_block_headings - current_block_headings
      deleted_headings.each do |heading|
        #warning: assumes that the heading is unique
        previous_block = other.time_blocks.select { |x| x.title == heading }.first
        block = preserve_deleted_timeblock(previous_block)
        blocks << block
      end
      change[:time_blocks] = blocks unless blocks.empty?
    end
    
    #the last bit - no change, no report; simples
    change[:pdf_info] = other.pdf_info unless change.empty?
    change
  end
  
  private
    def strip_heading_numbers(heading)
      heading.gsub(/^\d+\.\s*/, "").squeeze(" ")
    end
    
    def heading_in_list?(heading, heading_list)
      return true if heading_list.include?(heading)
      false
    end
    
    def compare_timeblock_with_previous_version(current, previous)
      block = {}
      block[:note] = previous.note unless previous.note == current.note
      block[:position] = previous.position unless previous.position == current.position
      block[:is_provisional] = previous.is_provisional unless previous.is_provisional == current.is_provisional
      bus_items = compare_business_items(current, previous)
      block[:business_items] = bus_items unless bus_items.empty?
      block
    end
    
    def preserve_deleted_timeblock(deleted_block)
      block = {}
      block[:change_type] = "deleted"
      block[:title] = deleted_block.title
      block[:note] = deleted_block.note if previous_block.note
      block[:position] = deleted_block.position
      block[:is_provisional] = deleted_block.is_provisional if deleted_block.is_provisional
      block[:pdf_info] = deleted_block.pdf_info
      bus_items = copy_business_items(deleted_block, block)
      block[:business_items] = bus_items unless bus_items.empty?
      block
    end
    
    def preserve_deleted_business_item(deleted_item)
      item = {}
      item[:change_type] = "deleted"
      item[:description] = deleted_item.description
      item[:position] = deleted_item.position
      item[:note] = deleted_item.note if deleted_item.note and deleted_item.note.empty? == false
      item[:pdf_info] = deleted_item.pdf_info
      item
    end
    
    def copy_business_items(previous_block, changes)
      items = []
      previous_block.business_items.each do |prev_item|
        item = preserve_deleted_business_item(prev_item)
        items << item
      end
      items
    end
    
    def compare_business_items(current_block, last_block)
      items = []
      
      current_headings = current_block.business_items.empty? ? [] : current_block.business_items.map { |x| x.description }
      previous_headings = last_block.business_items.empty? ? [] : last_block.business_items.map { |x| x.description }
      
      # loop over each heading (assumes uniqueness)
      current_headings.each do |heading|
        if heading_in_list?(\
            strip_heading_numbers(heading), \
            previous_headings.map { |x| strip_heading_numbers(x) })
          #pre-existing thing...
          desc = strip_heading_numbers(heading)
          current_item = current_block.business_items.select \
            { |x| strip_heading_numbers(x.description) == desc }.first
            
          previous_item = last_block.business_items.select \
            { |x| strip_heading_numbers(x.description) == desc }.first
          
          item = {}
          item[:note] = previous_item.note unless previous_item.note == current_item.note
          item[:position] = previous_item.position unless previous_item.position == current_item.position
          
          unless item.empty?
            item[:change_type] = "modified"
            item[:description] = previous_item.description
            item[:pdf_info] = previous_item.pdf_info
            items << item
          end
        else
          #a new thing, just need to note its arrival
          item = {}
          item[:change_type] = "new"
          item[:description] = heading
          items << item
        end
      end
      deleted_headings = previous_headings.map \
        { |x| strip_heading_numbers(x) } - current_headings.map { |x| strip_heading_numbers(x) }
      
      deleted_headings.each do |heading|
        #assumes that the heading is unique
        previous_item = last_block.business_items.select \
          { |x| strip_heading_numbers(x.description) == heading }.first
        
        item = preserve_deleted_business_item(previous_item)
        items << item
      end
      items
    end
end

class SittingDay < CalendarDay
  many :time_blocks
end

class NonSittingDay < CalendarDay
end

class TimeBlock
  include MongoMapper::EmbeddedDocument
  many :business_items
  
  key :time_as_number, Integer
  key :title, String
  key :note, String
  key :position, Integer
  key :is_provisional, Boolean
  key :pdf_info, Hash
end

class BusinessItem
  include MongoMapper::EmbeddedDocument
  
  key :description, String
  key :position, Integer
  key :note, String
  key :pdf_info, Hash
end