#encoding: utf-8

class OralQuestion < ActiveRecord::Base

 	def questioner()
    	complete.match(/^(.*)(?:&nbsp;|\s)to ask Her Majesty/)[1] 
  	end

  	def text()
    	    # /to ask Her Majesty.s Government (.*)$/.match(complete.split('.')[0])[1] + "."
    	# complete.split('.')[0].match(/to ask Her Majesty&rsquo;s Government(.*)/)
    	complete.split('.')[0].match(/s Government (.*)/)[1] + '.'
  	end

  	def answerer()
    	  /\. (.*) (?=\(.*\)\.)/.match(complete)[1]
  	end

  	def department()
  		complete.match(/(?<=\.).*\((.*)\)\.$/)[1]
  	end

end