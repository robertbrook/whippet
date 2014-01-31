#encoding: utf-8

class BusinessItem < ActiveRecord::Base
  belongs_to :time_block
  
  include Diffable
  set_excluded_fields :meta, :time_block_id
  set_unique_within_group :ident
  set_conditional_fields :meta
  
  def brief_summary
    description.match(/\d+\.?\s+([^–\[\(\\\/]*)/)[1].strip
  end
  
  def generate_ident
    "BusinessItem_#{brief_summary.downcase.gsub(" ", "_").gsub(/\W/, "")}"
  end
  
  def names
    if description.index('–')
      [description.split(" – ")[-1]]
    else
      []
    end
  end
  
end