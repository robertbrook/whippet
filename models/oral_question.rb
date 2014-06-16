class OralQuestion < ActiveRecord::Base

 	def questioner
    	"QUESTIONER " + self.complete
  	end

  	def text
    	"TEXT " + self.complete
  	end

  	def answerer
    	"ANSWERER " + self.complete
  	end

  	def date_sections
  		[]
  	end

end