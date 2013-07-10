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
  @calendar_days = CalendarDay.all(:order => :date.desc, :limit => 10)
  haml :index
end

get '/index.json' do  
  content_type :json
  @time = Time.now
  CalendarDay.all(:order => :date.desc, :limit => 10).to_json
end

get '/cal' do

  if params[:limit].to_i.between?(1, 20)
  	limit = params[:limit]
  else
  	limit = 4
  end
  	
  sitting_days = CalendarDay.all(:order => :date.desc, :limit => limit)
  
  if params.has_key?("ics") # will respond to cal?ics
    content_type 'text/calendar'
  else
  	content_type 'text/plain'
  end

ical_content = RiCal.Calendar { |ical|
sitting_days.each { |sitting_day|

  if sitting_day.has_time_blocks?
  sitting_day.time_blocks.each { |time_block|
    ical.event { |event|
      time_as_string = time_block.time_as_number.to_s.insert(2, ':')
      event.uid = time_block._id.to_s
      event.dtend = DateTime.parse(sitting_day.date.iso8601 + " " + time_as_string)
      event.dtstart = DateTime.parse(sitting_day.date.iso8601 + " " + time_as_string)
      event.summary = time_block.title
      event.description = time_block.title
      # pp block
    }
    }
  end
  }
  }

  ical_content.export

end
