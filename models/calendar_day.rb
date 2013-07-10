require "mongo_mapper"
require "./lib/mm_monkeypatch"

class CalendarDay
  include MongoMapper::Document
  
  key :date, Date
  key :note, String
  key :accepted, Boolean
  key :is_provisional, Boolean
  key :changes, Array
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
      current_block_headings.each do |heading|
        #assumes that the heading is unique
        current_block = self.has_time_blocks? ? time_blocks.select { |x| x.title == heading }.first : {}
        previous_block = other.has_time_blocks? ? other.time_blocks.select { |x| x.title == heading }.first : {}
        if heading_in_list?(heading, previous_block_headings)
          #pre-existing thing...
          block = {}
          block[:note] = previous_block.note unless previous_block.note == current_block.note
          block[:position] = previous_block.position unless previous_block.position == current_block.position
          block[:is_provisional] = previous_block.is_provisional unless previous_block.is_provisional == current_block.is_provisional
          bus_items = compare_business_items(current_block, previous_block)
          block[:business_items] = bus_items unless bus_items.empty?
          
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
      deleted_headings = previous_block_headings - current_block_headings
      deleted_headings.each do |heading|
        #assumes that the heading is unique
        previous_block = other.time_blocks.select { |x| x.title == heading }.first
        
        block = {}
        block[:change_type] = "deleted"
        block[:title] = previous_block.title
        block[:note] = previous_block.note if previous_block.note
        block[:position] = previous_block.position
        block[:is_provisional] = previous_block.is_provisional if previous_block.is_provisional
        block[:pdf_info] = previous_block.pdf_info
        bus_items = copy_business_items(previous_block, block)
        block[:business_items] = bus_items unless bus_items.empty?
        blocks << block
      end
      change[:time_blocks] = blocks unless blocks.empty?
    end
    
    #the last bit - no change, no report; simples
    #change[:pdf_info] = other.pdf_info unless change.empty?
    change
  end
  
  private
    def heading_in_list?(heading, heading_list)
      return true if heading_list.include?(heading)
      false
    end
    
    def copy_business_items(previous_block, changes)
      items = []
      previous_block.business_items.each do |prev_item|
        item = {}
        item[:change_type] = "deleted"
        item[:description] = prev_item.description
        item[:position] = prev_item.position
        item[:note] = prev_item.note if prev_item.note
        item[:pdf_info] = prev_item.pdf_info
        items << item
      end
      items
    end
    
    def compare_business_items(current_block, last_block)
      items = []
      
      current_headings = current_block.business_items.empty? ? [] : current_block.business_items.map { |x| x.description }
      previous_headings = last_block.business_items.empty? ? [] : last_block.business_items.map { |x| x.description }
      
      current_headings.each do |heading|
        if heading_in_list?(heading.gsub(/^\d+\.\s*/, ""), previous_headings.map { |x| x.gsub(/^\d+\.\s*/, "") })
          desc = heading.gsub(/^\d+\.\s*/, "")
          current_item = current_block.business_items.select { |x| x.description.gsub(/^\d+\.\s*/, "") == desc }.first
          previous_item = last_block.business_items.select { |x| x.description.gsub(/^\d+\.\s*/, "") == desc }.first
          
          #pre-existing thing...
          item = {}
          item[:change_type] = "modified"
          item[:description] = previous_item.description
          item[:note] = previous_item.note unless previous_item.note == current_item.note
          item[:position] = previous_item.position unless previous_item.position == current_item.position
          item[:pdf_info] = previous_item.pdf_info
          items << item
        else
          #a new thing, just need to note its arrival
          item = {}
          item[:change_type] = "new"
          item[:description] = heading
          items << item
        end
      end
      deleted_headings = previous_headings.map { |x| x.gsub(/^\d+\.\s*/, "") } - current_headings.map { |x| x.gsub(/^\d+\.\s*/, "") }
      deleted_headings.each do |heading|
        #assumes that the heading is unique
        previous_item = last_block.business_items.select { |x| x.description.gsub(/^\d+\.\s*/, "") == heading }.first
        
        item = {}
        item[:change_type] = "deleted"
        item[:description] = previous_item.description
        item[:note] = previous_item.note if previous_item.note
        item[:position] = previous_item.position
        item[:pdf_info] = previous_item.pdf_info
        
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