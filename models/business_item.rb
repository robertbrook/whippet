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
#     extract names from description and populate return
#     ["Where's the names then?"]
    []
  end
  
  
end