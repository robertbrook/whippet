require 'sinatra'
require 'mongoid'
require './lib/parser'
require 'haml'

before do
	if File.exist?("./config/mongo.yml")
  		Mongoid.load!("./config/mongo.yml")
  	else  		
  		# a bit lost here: ENV['MONGOHQ_DEV_URI']
  	end
end

get '/' do
  @time = Time.now
  @calendar_days = SittingDay.all.sort("date DESC").limit(10)
  haml :index
end
