xml.instruct! :xml, :version => '1.0'
xml.opml :version => "2.0" do
  xml.head do
    xml.title "Lords Whip"
    xml.ownerProfile "http://lordswhip.herokuapp.com"
    xml.ownerName "Lords Whip"
    xml.ownerEmail "mail@robertbrook.com"
    xml.dateModified
    xml.expansionState
  end
  xml.body do
    @calendar_days.each do |calendar_day|
      unless calendar_day.has_time_blocks?
        xml.outline(text: calendar_day.note, created: calendar_day.date.strftime("%A %e %B"))
      else
        xml.outline(text: calendar_day.date.strftime("%A %e %B"), created: calendar_day.date.strftime("%A %e %B")) do
          calendar_day.time_blocks.each do |block|
            xml.outline(text: block.time_as_number) do
              xml.outline(text: block.place)
              xml.outline(text: block.note || "(No note)") do
                block.business_items.each do |item|
                  xml.outline(text: item.description)
                end
              end
            end
          end
        end
      end
    end
  end
end


