require 'sinatra'
require 'mongoid'
require './lib/parser'

get '/' do
	@time = Time.now
  haml :index
end
