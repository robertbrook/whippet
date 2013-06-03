require 'sinatra'
require 'mongoid'
require './lib/parser'

before do
  Mongoid.load!("./config/mongo.yml")
end

get '/' do
  @time = Time.now
  @calendar_days = SittingDay.all.sort("date DESC").limit(10)
  haml :index
end
