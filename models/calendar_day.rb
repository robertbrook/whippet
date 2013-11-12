#encoding: utf-8

require "./lib/diffable.rb"

class CalendarDay < ActiveRecord::Base
  include Diffable
  set_excluded_from_copy :meta, :history
  set_conditional_fields :meta
  
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
end

class SittingDay < CalendarDay
  has_many :time_blocks, :dependent => :destroy
  set_excluded_from_copy :meta, :history
  set_unique_within_group :ident
  set_conditional_fields :meta
end

class NonSittingDay < CalendarDay
  set_excluded_from_copy :meta, :history
  set_unique_within_group :ident
  set_conditional_fields :meta
end
