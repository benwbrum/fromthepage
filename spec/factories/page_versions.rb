FactoryGirl.define do

  factory :page_version1, class: PageVersion do
    title "Saturday, June 10, 1922"
    transcription  "It was a dark and stormy night"
    xml_transcription  "<?xml version='1.0' encoding='ISO-8859-15'?><page>\n
    <p>It was a dark and stormy night</p></page>\n"
    user_id 1
    page_id 2
    work_version 1
    page_version 2

  end

end
