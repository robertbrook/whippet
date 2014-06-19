#encoding: utf-8

class OralQuestion < ActiveRecord::Base

 	def questioner()
    	  # /^(.*) to ask Her Majesty.s Government/.match(complete)[1]
            return complete.match(/^(.*)to ask Her Majesty/)[1]
            
  	end

  	def text()
    	    # /to ask Her Majesty.s Government (.*)$/.match(complete.split('.')[0])[1] + "."
          this = complete.split('.')[0].match(/to ask Her Majesty&rsquo;s Government(.*)$/)
          return this
  	end

  	def answerer()
    	  /\. (.*) (?=\(.*\)\.)/.match(complete)
  	end

  	def department()
  		/(?<=\.).*\((.*)\)\.$/.match(complete)
  	end

end