#encoding: utf-8

class SpeakerList < ActiveRecord::Base
  belongs_to :time_block
end