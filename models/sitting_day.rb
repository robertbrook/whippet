require "mongo_mapper"
require "./lib/mm_monkeypatch"

class SittingDay
  include MongoMapper::Document
  many :time_blocks
  
  key :date, Date
  key :note, String
  key :accepted, Boolean
  key :is_provisional, Boolean
  key :pdf_file, String
  key :pdf_page, String
  key :pdf_line, Integer
end

class TimeBlock
  include MongoMapper::EmbeddedDocument
  many :business_items
  
  key :time_as_number, Integer
  key :title, String
  key :note, String
  key :is_provisional, Boolean
  key :pdf_page, String
  key :pdf_line, Integer
end

class BusinessItem
  include MongoMapper::EmbeddedDocument
  
  key :description, String
  key :note, String
  key :pdf_page, String
  key :pdf_line, Integer
end