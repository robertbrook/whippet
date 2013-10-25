if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
end

require 'active_record'

ENV["RACK_ENV"] = "test" unless ENV["RACK_ENV"]
begin
  test = ActiveRecord::Base.connection
rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml'))[ENV["RACK_ENV"]])
end

require 'rspec/autorun'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.mock_framework = :mocha
end

require "mocha/api"