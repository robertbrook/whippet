require "mongo_mapper"
require "./lib/mm_monkeypatch"

class CalendarDay
  include MongoMapper::Document
  
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