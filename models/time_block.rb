#encoding: utf-8

class TimeBlock < ActiveRecord::Base
  belongs_to :sitting_day
  has_many :business_items, :dependent => :destroy
  has_one :speaker_list
  
  def place
    title.match(/Business (?:[a-z]+ )+((?:[A-Z][a-z]+ )+)/)[1].strip
  end
  
  def generate_ident
    "TimeBlock_#{place.downcase.gsub(" ", "_")}_#{time_as_number}"
  end
end
