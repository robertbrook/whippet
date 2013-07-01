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
    
    if self.has_time_blocks? or other.has_time_blocks?
      if self.has_time_blocks?
        current_block_headings = time_blocks.collect { |x| x.title }
      else
        current_block_headings = []
      end
      if other.has_time_blocks?
        previous_block_headings = other.time_blocks.collect { |x| x.title }
      else
        previous_block_headings = []
      end      
      diffs = Diff::LCS.diff(current_block_headings, previous_block_headings)
      unless diffs == []
        change[:time_block_headings] = diffs
        diffs = change[:time_block_headings].first
        #analyse changes
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
  key :is_provisional, Boolean
  key :pdf_info, Hash
end

class BusinessItem
  include MongoMapper::EmbeddedDocument
  
  key :description, String
  key :note, String
  key :pdf_info, Hash
end