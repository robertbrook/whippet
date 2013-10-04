#encoding: utf-8

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
  
  def source_docs
    pdfs = [pdf_info["filename"]]
    if time_blocks
      sub_docs = time_blocks.map { |block| block.business_items.map { |item| item.pdf_info["filename"] } }
      pdfs += sub_docs.flatten
    end
    pdfs.uniq.delete_if { |x| x.nil? }
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
  
  def find_in_array_by_id(arr, value)
    arr.select { |x| x.id == value }.first
  end
  
  def find_item_by_id(block, value)
    block.business_items.select { |x| x.id == value }.first
  end
  
  def map_timeblock_ids(day)
    day.has_time_blocks? ? day.time_blocks.map { |x| x.id } : []
  end
  
  def map_item_ids(block)
    block.business_items.empty? ? [] : block.business_items.map { |x| x.id }
  end
  
  def id_in_list?(id, id_list)
    return true if id_list.include?(id)
    false
  end
  
  def compare_current_blocks(current_block_ids, previous_block_ids, current_day, previous_day)
    blocks = []
    current_block_ids.each do |id|
      current_block = current_day.has_time_blocks? ? find_in_array_by_id(time_blocks, id) : {}
      previous_block = previous_day.has_time_blocks? ? find_in_array_by_id(previous_day.time_blocks, id) : {}
      if id_in_list?(id, previous_block_ids)
        #pre-existing thing, compare the differences...
        block = compare_timeblock_with_previous_version(current_block, previous_block)
        #...and only store if something's changed
        blocks << block unless block.empty?
      else
        #a new thing, just need to note its arrival
        blocks << {:title => current_block.title, :id => current_block.id, :change_type => "new"}
      end
    end
    blocks
  end
  
  def preserve_deleted_blocks(deleted_ids, previous_day)
    blocks = []
    deleted_ids.each do |id|
      previous_block = find_in_array_by_id(previous_day.time_blocks, id)
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
      current_block_ids = map_timeblock_ids(current_day)
      previous_block_ids = map_timeblock_ids(previous_day)
      
      #loop through the ids in the current block
      blocks += compare_current_blocks(current_block_ids, previous_block_ids, current_day, previous_day)
      
      #look for ids that only exist in the previous block
      blocks += preserve_deleted_blocks(previous_block_ids - current_block_ids, previous_day)
      
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
    unless previous_block.title == current_block.title
      block[:title] - previous_block.title
    end
    
    bus_items = compare_business_items(current_block, previous_block)
    unless bus_items.empty?
      block[:business_items] = bus_items
    end
    unless block.empty?
      block[:id] = current_block.id
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
    unless previous_item.description == current_item.description
      item[:description] = previous_item.description
    end
    
    unless item.empty?
      item[:change_type] = "modified"
      item[:description] = previous_item.description
      item[:id] = previous_item.id
      item[:pdf_info] = previous_item.pdf_info
    end
    item
  end
  
  def preserve_deleted_timeblock(deleted_block)
    block = {}
    block[:change_type] = "deleted"
    block[:id] = deleted_block.id
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
    item[:id] = deleted_item.id
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
    current_ids = map_item_ids(current_block)
    previous_ids = map_item_ids(previous_block)
    
    # loop over each id
    items = compare_current_items(current_ids, current_block, previous_ids, previous_block)
    
    #loop over the deleted items
    items += preserve_deleted_items(previous_ids - current_ids, previous_block)
    
    items
  end
  
  def compare_current_items(current_ids, current_block, previous_ids, previous_block)
    items = []
    current_ids.each do |id|
      if id_in_list?(id, previous_ids)
        #pre-existing thing...
        current_item = find_item_by_id(current_block, id)  
        previous_item = find_item_by_id(previous_block, id)
        
        item = compare_item_with_previous_version(current_item, previous_item)
        items << item unless item.empty?
      else
        #a new thing, just need to note its arrival
        item = {}
        item[:change_type] = "new"
        item[:id] = id
        item[:description] = find_item_by_id(current_block, id).description
        items << item
      end
    end
    items
  end
  
  def preserve_deleted_items(deleted_ids, previous_block)
    items = []
    deleted_ids.each do |id|
      previous_item = find_item_by_id(previous_block, id)
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
  
  def place
    title.match(/Business (?:[a-z]+ )+((?:[A-Z][a-z]+ )+)/)[1].strip
  end
  
  def generate_id
    "TimeBlock_#{place.downcase.gsub(" ", "_")}_#{time_as_number}"
  end
end

class BusinessItem
  include MongoMapper::EmbeddedDocument
  
  key :description, String
  key :position, Integer
  key :note, String
  key :pdf_info, Hash
  
  def brief_summary
    description.match(/\d+\.?\s+([^–\[\(\\\/]*)/)[1].strip
  end
  
  def generate_id
    "BusinessItem_#{brief_summary.downcase.gsub(" ", "_").gsub(/\W/, "")}"
  end
end