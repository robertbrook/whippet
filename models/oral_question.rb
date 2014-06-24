#encoding: utf-8
require 'nokogiri'

class OralQuestion < ActiveRecord::Base

 	def questioner()
    	  Nokogiri::HTML.fragment(complete).text().match(/(.*)to ask Her Majesty/)[1].gsub(/[[:space:]]/, ' ').strip

  	end

  	def text()
        Nokogiri::HTML.fragment(complete).text().match(/to ask Her Majesty.s Government(?:,?)(.*)/)[1].strip
  	end

  	def answerer()
      complete.match(/\.(?:\s?|&nbsp;?)(?:<strong.*>)(.*) (?=\(.*\)\.)/)[1]
  	end

  	def department()
  		complete.match(/(?<=\.).*\((.*)\)\./)[1]
  	end

end