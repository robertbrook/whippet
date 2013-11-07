#encoding: utf-8

class BusinessItem < ActiveRecord::Base
  belongs_to :time_block
  
  def brief_summary
    description.match(/\d+\.?\s+([^–\[\(\\\/]*)/)[1].strip
  end
  
  def generate_ident
    "BusinessItem_#{brief_summary.downcase.gsub(" ", "_").gsub(/\W/, "")}"
  end
  
  def get_attributes(excluded)
    attribs = attributes.dup
    attribs.delete_if { |key, value| excluded.include?(key) or key == "id" }
  end
  
  def unique_id_within_group
    "ident"
  end
  
  def excluded_fields
    ["meta", "history", "time_block_id"]
  end
end