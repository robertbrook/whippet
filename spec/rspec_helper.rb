if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
end

ENV["RACK_ENV"] = "test" unless ENV["RACK_ENV"]

require 'rspec/autorun'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.mock_framework = :mocha
end

require "mocha/api"