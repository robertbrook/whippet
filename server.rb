require 'sinatra'
require 'mongo_mapper'
require './lib/parser'
require 'haml'
require 'ri_cal'
require 'pp'

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
  calendar_days = SittingDay.all(:order => :date.desc, :limit => 10)
  # content_type 'text/calendar'

kal = RiCal.Calendar do |cal|
calendar_days.each do |calendar_day|
  calendar_day.time_blocks.each do |block|
    cal.event do |event|
      time_as_string = block.time_as_number.to_s.insert(2, ':')
      event.uid = block._id.to_s
      event.dtend = DateTime.parse(calendar_day.date.iso8601 + " " + time_as_string)
      event.dtstart = DateTime.parse(calendar_day.date.iso8601 + " " + time_as_string)
      event.transp = "OPAQUE"
      event.summary = block.title
      event.description = block.title
      pp block
    end
    end
  end
  end

  kal.export

end
