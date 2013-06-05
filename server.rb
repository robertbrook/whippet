require 'sinatra'
require 'mongoid'
require './lib/parser'
require 'haml'

@mongo_config = {"development"=>{"sessions"=>{"default"=>{"uri"=>ENV['MONGOHQ_DEV_URI']}}}, "production"=>{"sessions"=>{"default"=>{"uri"=>"mongodb://plausible_uri_production"}}}, "test"=>{"sessions"=>{"default"=>{"uri"=>"mongodb://admin:admin@dharma.mongohq.com:10061/whippet_test"}}}}

before do
	if File.exist?("./config/mongo.yml")
  		Mongoid.load!("./config/mongo.yml")
  	else
  		Mongoid.load!(@mongo_config)
  	end
end

get '/' do
  @time = Time.now
  @calendar_days = SittingDay.all.sort("date DESC").limit(10)
  haml :index
end
