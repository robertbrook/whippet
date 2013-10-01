xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Lords Whip"
    xml.description "Lords Whip"
    xml.link "http://lordswhip.herokuapp.com"

    @calendar_days.each do |calendar_day|
      xml.item do
        xml.title "TITLE"
        xml.link "LINK"
        xml.description "DESCRIPTION"
        xml.pubDate "PUBDATE"
        xml.guid "GUID"
      end
    end
  end
end