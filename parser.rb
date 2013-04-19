require "rubygems"
require "pdf/reader"

pdf = PDF::Reader.new("FB 2013 03 27 r.pdf")
mytext = ""

pdf.pages.each do |page|
	mytext << page.text
end

mytext.lines.each do |line|

	case line

        when /Information/
            break

		when /\b([A-Z]{2,}[DAY] \d.+)/
			@dateflag = $1
            @itemflag = ""
			puts
			puts
    		puts @dateflag

    	when /^(\d)/
            @itemflag = $1
    		puts "\t\t" + line

    	when /^([A-Z])/
    		puts "\t" + line

    	when /^\n$/
    		p

        #when /^[    ]/
        #    if @itemflag == ""
        #        puts "..." + line
        #    end

		when
            if @itemflag == ""
                puts line
            else
                puts @itemflag.to_s + "\t\t" + line
            end

		end
end