require "mongo_mapper"
require "./lib/mm_monkeypatch"
require "diff/lcs"

class CalendarDay
  include MongoMapper::Document
  
  def has_time_blocks?
    return true if respond_to?(:time_blocks) and time_blocks.count > 0
    false
  end
  
  def diff(other)
    change = {}
    unless other.is_a?(CalendarDay)
      raise "Unable to compare #{self.class} to #{other.class}"
    end
    
    #the easy bit - fixed simple values
    comp_note = note.nil? ? "" : note
    other_note = other.note.nil? ? "" : other.note
    change[:note] = Diff::LCS.diff(comp_note, other_note) if note != other.note
    change[:_type] = other._type if _type != other._type
    change[:accepted] = other.accepted if accepted != other.accepted
    change[:is_provisional] = other.is_provisional if is_provisional != other.is_provisional
    
    #analyse the time_blocks
    if self.has_time_blocks? or other.has_time_blocks?
      current_block_headings = self.has_time_blocks? ? time_blocks.collect { |x| x.title } : []
      previous_block_headings = other.has_time_blocks? ? other.time_blocks.collect { |x| x.title } : []
      current_block_headings.each do |heading|
        if heading_in_list?(heading, previous_block_headings)
          #pre-existing thing...
          #do comparisons, including positioning
        else
          #a new thing!
        end
        deleted_headings = previous_block_headings - current_block_headings
        unless deleted_headings.empty?
          #process the deleted things
        end
      end
    end
    
    #the last bit - no change, no report; simples
    change[:pdf_info] = other.pdf_info unless change.empty?
    change
  end
  
  def becomes(klass)
    became = klass.new
    self.instance_variables.each do |var|
      became.instance_variable_set("#{var}", self.instance_variable_get(var))
    end
    became._type = klass.name
    became
  end
  
  key :date, Date
  key :note, String
  key :accepted, Boolean
  key :is_provisional, Boolean
  key :changes, Array
  key :pdf_info, Hash
  
  private
    def heading_in_list?(heading, heading_list)
      return true if heading_list.include?(heading)
      false
    end
    
    def diff_business_items(block, other_block=nil)
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