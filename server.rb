require 'sinatra'
require 'mongoid'
require './lib/parser'


@mongo_config = <<END
development:
  sessions:
    default:
      uri: <%= ENV['MONGOHQ_DEV_URI'] %>

production:
  sessions:
    default:
      uri:
         
test:
  sessions:
    default:
      uri:
END


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
