require "mongoid"

class SittingDay
  include Mongoid::Document
  embeds_many :time_blocks
  
  field :date, type: Date
  field :note, type: String
end

class TimeBlock
  include Mongoid::Document
  embeds_many :business_items
  embedded_in :sitting_day
  
  field :time_as_number, type: Integer
  field :title, type: String
  field :note, type: String
  field :is_provisional, type: Boolean
end

class BusinessItem
  include Mongoid::Document
  embedded_in :time_block
  
  field :description, type: String
  field :note, type: String
end