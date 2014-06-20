#encoding: utf-8

class OralQuestion < ActiveRecord::Base

 	def questioner()
    	complete.match(/^(.*)(?:&nbsp;|\s)to ask Her Majesty/)[1] 
  	end

  	def text()
    	complete.split('.')[0].match(/s Government (.*)/)[1] + '.'
  	end

  	def answerer()
    	  /\. (.*) (?=\(.*\)\.)/.match(complete)[1]
  	end

  	def department()
  		complete.match(/(?<=\.).*\((.*)\)\.$/)[1]
  	end

end