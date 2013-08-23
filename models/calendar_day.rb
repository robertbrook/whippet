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
    unless other.is_a?(CalendarDay)
      raise "Unable to compare #{self.class} to #{other.class}"
    end
    
    #compare the simple values
    change = compare_simple_values(self, other)
    
    #analyse the time_blocks
    change = analyze_time_blocks(self, other, change)
    
    #the last bit - no change, no report; simples
    change[:pdf_info] = other.pdf_info unless change.empty?
    change
  end
  
  
  private
  
  def strip_heading_numbers(heading)
    heading.gsub(/^\d+\.\s*/, "").squeeze(" ")
  end
  
  def find_in_array_by_title(arr, value)
    arr.select { |x| x.title == value }.first
  end
  
  def find_item_by_unnumbered_description(block, value)
    block.business_items.select \
      { |x| strip_heading_numbers(x.description) == value }.first
  end
  
  def map_timeblock_titles(obj)
    obj.has_time_blocks? ? obj.time_blocks.map { |x| x.title } : []
  end
  
  def map_item_descriptions(block)
    block.business_items.empty? ? [] : block.business_items.map { |x| x.description }
  end
  
  def map_unnumbered_descriptions(block)
    block.map { |x| strip_heading_numbers(x) }
  end
  
  def heading_in_list?(heading, heading_list)
    return true if heading_list.include?(heading)
    false
  end
  
  def compare_current_blocks(current_block_headings, previous_block_headings, current_day, previous_day)
    blocks = []
    current_block_headings.each do |heading|
      #warning: assumes that the heading is unique
      current_block = current_day.has_time_blocks? ? find_in_array_by_title(time_blocks, heading) : {}
      previous_block = previous_day.has_time_blocks? ? find_in_array_by_title(previous_day.time_blocks, heading) : {}
      if heading_in_list?(heading, previous_block_headings)
        #pre-existing thing, compare the differences...
        block = compare_timeblock_with_previous_version(current_block, previous_block)
        #...and only store if something's changed
        blocks << block unless block.empty?
      else
        #a new thing, just need to note its arrival
        blocks << {:title => current_block.title, :change_type => "new"}
      end
    end
    blocks
  end
  
  def preserve_deleted_blocks(deleted_headings, previous_day)
    blocks = []
    deleted_headings.each do |heading|
      #warning: assumes that the heading is unique
      previous_block = find_in_array_by_title(previous_day.time_blocks, heading)
      block = preserve_deleted_timeblock(previous_block)
      blocks << block
    end
    blocks
  end
  
  def compare_simple_values(current_day, previous_day, change={})
    change[:note] = previous_day.note if current_day.note.to_s != previous_day.note.to_s
    change[:_type] = previous_day._type if current_day._type != previous_day._type
    change[:accepted] = previous_day.accepted if current_day.accepted != previous_day.accepted
    change[:is_provisional] = previous_day.is_provisional if current_day.is_provisional != previous_day.is_provisional
    change
  end
  
  def analyze_time_blocks(current_day, previous_day, change={})
    if current_day.has_time_blocks? or previous_day.has_time_blocks?
      blocks = []
      current_block_headings = map_timeblock_titles(current_day)
      previous_block_headings = map_timeblock_titles(previous_day)
      
      #loop through headings in the current block
      blocks += compare_current_blocks(current_block_headings, previous_block_headings, current_day, previous_day)
      
      #look for headings only exist in the previous block
      blocks += preserve_deleted_blocks(previous_block_headings - current_block_headings, previous_day)
      
      #update time_blocks if any changes were found
      change[:time_blocks] = blocks unless blocks.empty?
    end
    change
  end
  
  def compare_timeblock_with_previous_version(current_block, previous_block)
    block = {}
    unless previous_block.note == current_block.note
      block[:note] = previous_block.note
    end
    unless previous_block.position == current_block.position
      block[:position] = previous_block.position
    end
    unless previous_block.is_provisional == current_block.is_provisional
      block[:is_provisional] = previous_block.is_provisional
    end
    
    bus_items = compare_business_items(current_block, previous_block)
    unless bus_items.empty?
      block[:business_items] = bus_items
    end
    unless block.empty?
      block[:title] = current_block.title
      block[:change_type] = "modified"
      block[:pdf_info] = previous_block.pdf_info
    end
    block
  end
  
  def compare_item_with_previous_version(current_item, previous_item)
    item = {}
    unless previous_item.note == current_item.note
      item[:note] = previous_item.note
    end
    unless previous_item.position == current_item.position
      item[:position] = previous_item.position
    end
    
    unless item.empty?
      item[:change_type] = "modified"
      item[:description] = previous_item.description
      item[:pdf_info] = previous_item.pdf_info
    end
    item
  end
  
  def preserve_deleted_timeblock(deleted_block)
    block = {}
    block[:change_type] = "deleted"
    block[:title] = deleted_block.title
    block[:note] = deleted_block.note if deleted_block.note
    block[:position] = deleted_block.position
    block[:is_provisional] = deleted_block.is_provisional if deleted_block.is_provisional
    block[:pdf_info] = deleted_block.pdf_info
    bus_items = copy_business_items(deleted_block, block)
    block[:business_items] = bus_items unless bus_items.empty?
    block
  end
  
  def preserve_deleted_item(deleted_item)
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
      item = preserve_deleted_item(prev_item)
      items << item
    end
    items
  end
  
  def compare_business_items(current_block, previous_block)
    current_headings = map_item_descriptions(current_block)
    previous_headings = map_item_descriptions(previous_block)
    
    # loop over each heading (assumes uniqueness)
    items = compare_current_items(current_headings, current_block, previous_headings, previous_block)
    
    #loop over the deleted items
    items += preserve_deleted_items(\
      map_unnumbered_descriptions(previous_headings) - map_unnumbered_descriptions(current_headings), 
      previous_block)
    
    items
  end
  
  def compare_current_items(current_headings, current_block, previous_headings, previous_block)
    items = []
    current_headings.each do |heading|
      if heading_in_list?(\
          strip_heading_numbers(heading), \
          map_unnumbered_descriptions(previous_headings))
        #pre-existing thing...
        desc = strip_heading_numbers(heading)
        current_item = find_item_by_unnumbered_description(current_block, desc)  
        previous_item = find_item_by_unnumbered_description(previous_block, desc)
        
        item = compare_item_with_previous_version(current_item, previous_item)
        items << item unless item.empty?
      else
        #a new thing, just need to note its arrival
        item = {}
        item[:change_type] = "new"
        item[:description] = heading
        items << item
      end
    end
    items
  end
  
  def preserve_deleted_items(deleted_headings, previous_block)
    items = []
    deleted_headings.each do |heading|
      #assumes that the heading is unique
      previous_item = find_item_by_unnumbered_description(previous_block, heading)        
      item = preserve_deleted_item(previous_item)
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