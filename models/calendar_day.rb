require "mongo_mapper"
require "./lib/mm_monkeypatch"
require "diff/lcs"

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
      blocks = []
      current_block_headings = self.has_time_blocks? ? time_blocks.collect { |x| x.title } : []
      previous_block_headings = other.has_time_blocks? ? other.time_blocks.collect { |x| x.title } : []
      current_block_headings.each do |heading|
        #assumes that the heading is unique
        current_block = self.has_time_blocks? ? time_blocks.select { |x| x.title = heading }.first : {}
        previous_block = other.has_time_blocks? ? other.time_blocks.select { |x| x.title = heading }.first : {}
        if heading_in_list?(heading, previous_block_headings)
          block = {}
          #pre-existing thing...
          #do comparisons, including positioning
        else
          #a new thing, just need to note it's arrival
          blocks << {:title => current_block.title, :change_type => "new"}
        end
      end
      deleted_headings = previous_block_headings - current_block_headings
      deleted_headings.each do |heading|
        #assumes that the heading is unique
        previous_block = other.time_blocks.select { |x| x.title = heading }.first        
        block = {}
        block[:change_type] = "deleted"
        block[:title] = previous_block.title
        block[:note] = previous_block.note
        block[:position] = previous_block.position
        block[:is_provisional] = previous_block.is_provisional
        block[:pdf_info] = previous_block.pdf_info
        #stash all the business_items also
      end
      change[:time_blocks] = blocks unless blocks.empty?
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