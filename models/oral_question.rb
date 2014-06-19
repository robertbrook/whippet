class OralQuestion < ActiveRecord::Base

 	def questioner
    	/^(.*) to ask Her Majesty/.match(complete)[1]
  	end

  	def text
    	"TEXT " + self.complete
  	end

  	def answerer
    	/\. (.*) (?=\(.*\)\.)/.match(complete)[1]
  	end

  	def department
  		/(?<=\.).*\((.*)\)\.$/.match(complete)[1]
  	end

  	def date_sections
  		[]
  	end

end