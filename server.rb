require 'sinatra'
require 'active_record'
require 'haml'
require 'ri_cal'
require 'erb'

require './models/calendar_day'
require './models/time_block'
require './models/business_item'
require './models/speaker_list'

before do
  env = ENV["RACK_ENV"] ? ENV["RACK_ENV"] : "development"
  if ENV["DATABASE_URL"] #hai heroku
    config = YAML.load(ERB.new(File.read('config/database.yml')).result)
  else
    config = YAML::load(File.open('config/database.yml'))
  end
  ActiveRecord::Base.establish_connection(config[env])
end

helpers do
  def get_pdf_scope(filename)
    postgres = `postgres --version`
    matches = postgres.scan /(\d+.\d+.\d+)/
    version = matches.flatten.first.split(".")
    days = []
    if version[0].to_i > 8 and version[1].to_i > 2
      # 9.3.x or better? Great, use the full json query syntax
      days = CalendarDay.where("meta->'pdf_info'->>'filename' = ?", "#{filename}").order("date asc")
    else
      # ah, ok - workaround time. This could go wrong - it might pickup subobjects with the matching filename
      # hmm. I should rip this off.
      days = CalendarDay.where("meta::text like ?", %Q|%"filename":"#{filename}"%|).order("date asc")
    end
    unless days.empty?
      [days.first.date, days.last.date]
    else
      []
    end
  end
end

@time = Time.now

get '/' do
  @page = params[:page].to_i > 0 ? params[:page].to_i : 1
  @total = CalendarDay.count
  @offset = (@page - 1) * 10
  @calendar_days = CalendarDay.order("date desc").limit(10).offset(@offset)
  haml :index
end

get '/index.txt' do  
  content_type :text
  "text output here"
end

get '/index.json' do  
  content_type :json
  CalendarDay.order("date desc").limit(10).to_json
end

get '/index.xml' do  
  content_type :xml
  CalendarDay.order("date desc").limit(10).to_xml
end

get '/index.rss' do
  @calendar_days = CalendarDay.order("date desc").limit(10)
  builder :rss
end

get '/index.opml' do
  @calendar_days = CalendarDay.order("date desc").limit(10)
  builder :opml
end

get '/index.ics' do
  content_type 'text/calendar'
  if params[:limit].to_i.between?(1, 20)
  	limit = params[:limit]
  else
  	limit = 4
  end
  	
  sitting_days = CalendarDay.order("date desc").limit(limit)

ical_content = RiCal.Calendar { |ical|
sitting_days.each { |sitting_day|

  if sitting_day.has_time_blocks?
  sitting_day.time_blocks.each { |time_block|
    ical.event { |event|
      time_as_string = time_block.time_as_number.to_s.insert(2, ':')
      event.uid = time_block.ident
      event.dtend = DateTime.parse(sitting_day.date.iso8601 + " " + time_as_string)
      event.dtstart = DateTime.parse(sitting_day.date.iso8601 + " " + time_as_string)
      event.summary = time_block.title
      event.description = time_block.title
    }
    }
  end
  }
  }

  ical_content.export

end

get "/search.?:format?" do
  unless params[:q].empty? and params[:q] != '+'
    @items = BusinessItem.where("description ILIKE ?", '%' + params[:q] + '%')
    @format = params[:format]
    if @items.length > 0
      @subtitle = "Search results"
    else
      @subtitle = "No results found"
    end
    haml :search
  else
    @items = []
    @subtitle = "sorry: I need something to search for"
    haml :search
  end
end

get "/:date.json" do
  content_type :json
  unless params[:date] and params[:date] =~ /\d{4}-\d{1,2}-\d{1,2}/
    halt 403, {:error => "need to supply a date in the format yyyy-mm-dd"}.to_json
  end
  parsed_time = Time.parse(params[:date]).strftime("%Y-%m-%d 00:00:00Z")
  day = CalendarDay.where(:date => Time.parse(parsed_time)).first
  unless day
    halt 404, {:error => "no data for supplied date #{params[:date]}"}.to_json
  end
  day.to_json
end

# get "/search/:search_text.xml" do
#   content_type :xml
#   items = BusinessItem.where("description ILIKE ?", '%' + params[:search_text] + '%')
#   items.to_xml
# end
# 
# get "/search/:search_text.json" do
#   content_type :json
#   items = BusinessItem.where("description ILIKE ?", '%' + params[:search_text] + '%')
#   items.to_json
# end

get "/:date" do
  if params[:date] and params[:date] =~ /\d{4}-\d{1,2}-\d{1,2}/
    "html for #{params[:date]}"
  end
end

get "/edit-mockup" do
  if params[:date]
    @date = Time.parse(params[:date])
    @day = CalendarDay.where(:date => Time.parse(@date.strftime("%Y-%m-%d 00:00:00Z"))).first
  else
    @day = SittingDay.first
    p = SittingDay.first
    @date = @day.date
  end
  @editing = true
  haml :edit_mockup
end

get "/pdf/:filename" do
  file = params[:filename]
  send_file File.expand_path("data/#{file}")
end

get '/editor' do  
  @calendar_days_json = CalendarDay.order("date desc").limit(10).to_json
  @hulk = true
  haml :editor
end

get "/pdf-list" do
  @pdfs = Dir['./data/*.pdf'].map { |x| File.basename(x) }
  haml :pdf_list
end

