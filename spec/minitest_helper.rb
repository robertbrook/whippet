ENV["RACK_ENV"] = "test"

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
end

require 'minitest/autorun'
require 'mocha/setup'
