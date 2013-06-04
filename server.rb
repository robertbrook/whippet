require 'sinatra'
require 'mongoid'
require './lib/parser'

# to wire up with fake struct later
# MONGOHQ_DEV_URI = ENV['MONGOHQ_DEV_URI'] || YAML::load(File.read("./config/mongo.yml"))[:websolr_url]

before do
  Mongoid.load!("./config/mongo.yml")
end

get '/' do
  @time = Time.now
  @calendar_days = SittingDay.all.sort("date DESC").limit(10)
  haml :index
end
