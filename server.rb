require 'sinatra'
require 'mongo_mapper'
require './lib/parser'
require 'haml'
require 'ri_cal'

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

get '/cal' do
  @time = Time.now
  @calendar_days = SittingDay.all(:order => :date.desc, :limit => 10)
  # content_type 'text/calendar'
  @calendar_days.each do |day|
#   puts day._id
  @cal = RiCal.Calendar do
    event do
      summary    "The 'title' of the event"
      description "MA-6 First US Manned Spaceflight"
      dtstart     DateTime.parse("2013-06-17 3pm")
      dtend       DateTime.parse("2013-06-17 6pm")
      location    "Cape Canaveral"
    end
    
  end
  end
  @cal.export

end
