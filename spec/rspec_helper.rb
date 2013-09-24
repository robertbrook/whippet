if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
end

require 'rspec/autorun'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end