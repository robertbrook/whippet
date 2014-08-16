source "http://rubygems.org"

gem 'sinatra'
gem 'pdf-reader'
gem 'pdf-reader-markup'
gem 'rest-client'
gem 'nokogiri'
gem 'activerecord', '~> 4.0.0'
gem 'pg'
gem 'json', '~> 1.8.1'
gem 'activerecord-postgresql-adapter'
gem 'rake'
gem 'haml', :require => 'haml'
gem 'ri_cal'
gem 'rspec'
gem 'diffable'
gem 'unicorn'
gem 'coffee-script'
gem 'logger'

group :production do
  ruby '1.9.3'
  gem 'thin'
end

group :development do
  gem 'shotgun'
  gem 'tux'
end

group :test do
  gem 'mocha'
  gem 'simplecov', '0.7.1'
  gem 'rack-test'
  # gem 'autotest'
end
