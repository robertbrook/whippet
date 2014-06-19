class OralQuestion < ActiveRecord::Base

 	def questioner
    	/^(.*) to ask Her Majesty.s Government/.match(complete)[1]
  	end

  	def text
    	/to ask Her Majesty.s Government (.*)$/.match(complete.split('.')[0])[1] + "."
  	end

  	def answerer
    	/\. (.*) (?=\(.*\)\.)/.match(complete)[1]
  	end

  	def department
  		/(?<=\.).*\((.*)\)\.$/.match(complete)[1]
  	end

end