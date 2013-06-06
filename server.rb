require 'sinatra'
require 'mongo_mapper'
require './lib/parser'
require 'haml'

before do
  if db = ENV["MONGOHQ_DEV_URI"]
    MongoMapper.setup({'production' => {'uri' => db}}, 'production')
  else
    env = ENV['RACK_ENV']
    MongoMapper.setup({"#{env}" => {'uri' => YAML::load_file("./config/mongo.yml")[env]['uri']}}, env)
  end
end

get '/' do  
  @time = Time.now
  @calendar_days = SittingDay.all(:order => :date.desc, :limit => 10)
  haml :index
end