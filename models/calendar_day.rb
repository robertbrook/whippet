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
      diffs = Diff::LCS.diff(current_block_headings, previous_block_headings)
      unless diffs == []
        change[:time_block_headings] = diffs
        analyse_diffs(change, change[:time_block_headings].first, self.time_blocks, other.time_blocks)
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
    def analyse_diffs(change, diffs, new_time_blocks, old_time_blocks)
      added_blocks = diffs.select { |x| x.adding? == false }
      removed_blocks = diffs.select { |x| x.adding? }
      if diffs.length > 1
        #things were added and things were taken away
        removed_headings = removed_blocks.collect { |x| x.to_a.last }
        added_blocks.each do |added|
          heading = added.to_a.last
          if heading_moved?(heading, removed_headings, true)
            #it's been moved, not _removed_
            #something different needs to be done
            diff_business_items(added)
          end
        end
      elsif added_blocks.empty?
        #thing(s) removed
        removed_blocks.each do |block|
          #record what the thing used to be
          #and where it (last) came from
          diff_business_items(block)
        end
      end
    end
    
    def heading_moved?(heading, heading_list, check_time=false)
      return true if heading_list.include?(heading)
      if check_time
        heading_list.each do |old_heading|
          if old_heading =~ /Business in (.*) at (.*)/
            chamber = $1
            time = $2
            if heading =~ /Business in (.*) at (.*)/
              if $1 == chamber and $2 != time
                #p "time change: was #{$2}, now #{time}"
                return true
              end
            end
          end
        end
      end
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