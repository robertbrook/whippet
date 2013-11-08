source "http://rubygems.org"

gem 'sinatra'
gem 'pdf-reader'
gem 'rest-client'
gem 'nokogiri'
gem 'activerecord', '~> 4.0.0'
gem 'pg'
gem 'json', '~> 1.7.7'
gem 'rake'
gem 'haml', :require => 'haml'
gem 'ri_cal'
gem 'rspec'

group :production do
  ruby '1.9.3'
  gem 'thin'
end

group :development do
  gem 'shotgun'
end

group :test do
  gem 'mocha'
  gem 'simplecov', '0.7.1'
  gem 'rack-test'
  # gem 'autotest'
end