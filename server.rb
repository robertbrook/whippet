require 'sinatra'
require 'mongoid'
require './lib/parser'

# MONGO_CONFIG = @mongo_config_template || "./config/mongo.yml"

@mongo_config_template = <<END
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
  Mongoid.load!(@mongo_config_template || "./config/mongo.yml")
end

get '/' do
  @time = Time.now
  @calendar_days = SittingDay.all.sort("date DESC").limit(10)
  haml :index
end
