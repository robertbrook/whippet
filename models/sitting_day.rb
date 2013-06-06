require "mongo_mapper"
require "./lib/mm_monkeypatch"

class SittingDay
  include MongoMapper::Document
  many :time_blocks
  
  key :date, Date
  key :note, String
  key :accepted, Boolean
  key :pdf_file, String
end

class TimeBlock
  include MongoMapper::EmbeddedDocument
  many :business_items
  
  key :time_as_number, Integer
  key :title, String
  key :note, String
  key :is_provisional, Boolean
end

class BusinessItem
  include MongoMapper::EmbeddedDocument
  
  key :description, String
  key :note, String
end