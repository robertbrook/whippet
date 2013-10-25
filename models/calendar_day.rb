#encoding: utf-8

class CalendarDay < ActiveRecord::Base
  def has_time_blocks?
    if respond_to?(:time_blocks)
      return true unless time_blocks.empty?
    end
    false
  end
  
  def becomes(klass)
    became = klass.new
    self.instance_variables.each do |var|
      became.instance_variable_set("#{var}", self.instance_variable_get(var))
    end
    became.type = klass.name
    became
  end
  
  def source_docs
    pdfs = [meta["pdf_info"]["filename"]]
    if time_blocks
      sub_docs = time_blocks.map { |block| block.business_items.map { |item| (item.meta && item.meta["pdf_info"]) ? item.meta["pdf_info"]["filename"] : nil }}
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
    change[:meta] = other.meta unless change.empty?
    change
  end
  
  
  private
  
  def find_in_array_by_ident(arr, value)
    arr.select { |x| x.ident == value }.first
  end
  
  def find_item_by_ident(block, value)
    block.business_items.select { |x| x.ident == value }.first
  end
  
  def map_timeblock_idents(day)
    day.has_time_blocks? ? day.time_blocks.map { |x| x.ident } : []
  end
  
  def map_item_idents(block)
    block.business_items.empty? ? [] : block.business_items.map { |x| x.ident }
  end
  
  def ident_in_list?(id, id_list)
    return true if id_list.include?(id)
    false
  end
  
  def compare_current_blocks(current_block_idents, previous_block_idents, current_day, previous_day)
    blocks = []
    current_block_idents.each do |ident|
      current_block = current_day.has_time_blocks? ? find_in_array_by_ident(time_blocks, ident) : {}
      previous_block = previous_day.has_time_blocks? ? find_in_array_by_ident(previous_day.time_blocks, ident) : {}
      
      if ident_in_list?(ident, previous_block_idents)
        #pre-existing thing, compare the differences...
        block = compare_timeblock_with_previous_version(current_block, previous_block)
        #...and only store if something's changed
        blocks << block unless block.empty?
      else
        #a new thing, just need to note its arrival
        blocks << {:title => current_block.title, :ident => current_block.ident, :change_type => "new"}
      end
    end
    blocks
  end
  
  def preserve_deleted_blocks(deleted_idents, previous_day)
    blocks = []
    deleted_idents.each do |ident|
      previous_block = find_in_array_by_ident(previous_day.time_blocks, ident)
      block = preserve_deleted_timeblock(previous_block)
      blocks << block
    end
    blocks
  end
  
  def compare_simple_values(current_day, previous_day, change={})
    change[:note] = previous_day.note if current_day.note.to_s != previous_day.note.to_s
    change[:type] = previous_day.type if current_day.type != previous_day.type
    change[:accepted] = previous_day.accepted if current_day.accepted != previous_day.accepted
    change[:is_provisional] = previous_day.is_provisional if current_day.is_provisional != previous_day.is_provisional
    change
  end
  
  def analyze_time_blocks(current_day, previous_day, change={})
    if current_day.has_time_blocks? or previous_day.has_time_blocks?
      blocks = []
      current_block_idents = map_timeblock_idents(current_day)
      previous_block_idents = map_timeblock_idents(previous_day)
      
      #loop through the ids in the current block
      blocks += compare_current_blocks(current_block_idents, previous_block_idents, current_day, previous_day)
      
      #look for ids that only exist in the previous block
      blocks += preserve_deleted_blocks(previous_block_idents - current_block_idents, previous_day)
      
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
    unless previous_block.title == current_block.title
      block[:title] = previous_block.title
    end
    
    bus_items = compare_business_items(current_block, previous_block)
    unless bus_items.empty?
      block[:business_items] = bus_items
    end
    unless block.empty?
      block[:ident] = current_block.ident
      block[:title] = current_block.title
      block[:change_type] = "modified"
      block[:meta] = previous_block.meta
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
      item[:ident] = previous_item.ident
      item[:meta] = previous_item.meta
    end
    item
  end
  
  def preserve_deleted_timeblock(deleted_block)
    block = {}
    block[:change_type] = "deleted"
    block[:ident] = deleted_block.ident
    block[:title] = deleted_block.title
    block[:note] = deleted_block.note if deleted_block.note
    block[:position] = deleted_block.position
    block[:meta] = deleted_block.meta
    bus_items = copy_business_items(deleted_block, block)
    block[:business_items] = bus_items unless bus_items.empty?
    block
  end
  
  def preserve_deleted_item(deleted_item)
    item = {}
    item[:change_type] = "deleted"
    item[:description] = deleted_item.description
    item[:ident] = deleted_item.ident
    item[:position] = deleted_item.position
    item[:note] = deleted_item.note if deleted_item.note and deleted_item.note.empty? == false
    item[:meta] = deleted_item.meta
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
    current_idents = map_item_idents(current_block)
    previous_idents = map_item_idents(previous_block)
    
    # loop over each id
    items = compare_current_items(current_idents, current_block, previous_idents, previous_block)
    
    #loop over the deleted items
    items += preserve_deleted_items(previous_idents - current_idents, previous_block)
    
    items
  end
  
  def compare_current_items(current_idents, current_block, previous_idents, previous_block)
    items = []
    current_idents.each do |ident|
      if ident_in_list?(ident, previous_idents)
        #pre-existing thing...
        current_item = find_item_by_ident(current_block, ident)
        previous_item = find_item_by_ident(previous_block, ident)
        
        item = compare_item_with_previous_version(current_item, previous_item)
        items << item unless item.empty?
      else
        #a new thing, just need to note its arrival
        item = {}
        item[:change_type] = "new"
        item[:ident] = ident
        item[:description] = find_item_by_ident(current_block, ident).description
        items << item
      end
    end
    items
  end
  
  def preserve_deleted_items(deleted_idents, previous_block)
    items = []
    deleted_idents.each do |ident|
      previous_item = find_item_by_ident(previous_block, ident)
      item = preserve_deleted_item(previous_item)
      items << item
    end
    items
  end
end

class SittingDay < CalendarDay
  has_many :time_blocks, :dependent => :destroy
end

class NonSittingDay < CalendarDay
end
