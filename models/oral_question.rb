class OralQuestion < ActiveRecord::Base

 	def questioner
    	/^(.*) to ask Her Majesty/.match(complete)[1]
  	end

  	def text
    	complete.split('.')[0]
  	end

  	def answerer
    	/\. (.*) (?=\(.*\)\.)/.match(complete)[1]
  	end

  	def department
  		/(?<=\.).*\((.*)\)\.$/.match(complete)[1]
  	end

end