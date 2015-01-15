require "spec_helper"
require "search_translator"

# This spec describes the features and experience a reader should
# have using the site
#

XML_TEXT = <<EOF
<?xml version='1.0' encoding='ISO-8859-15'?>    
      <page>
        <p>A very <link target_title='rain' link_id='77064' target_id='49'>rainy</link> day the children 
<lb/>did not go to <link target_title='school' link_id='77065' target_id='254'>school</link>.  <link target_title='Benjamin Franklin Brumfield, Sr.' link_id='77066' target_id='4'>Ben</link> worked 
<lb/>on <link target_title='Sam Owen' link_id='77067' target_id='188'>Owens</link> <link target_title='tenant house' link_id='77068' target_id='181'>house</link>.
</p><p><link target_title='Sally Joseph Carr Brumfield' link_id='77069' target_id='1627'>Josie</link> &amp; <link target_title='sewing' link_id='77070' target_id='29'>sewed</link> a little 
<lb/>today was <link target_title='Carrie Smith' link_id='77071' target_id='32'>Carries</link> birth day.  
<lb/>I had thought I would go 
<lb/>to see her but it <link target_title='rain' link_id='77072' target_id='49'>rained</link> 
<lb/>so that I could not go.  
<lb/>I had a <link target_title='letter' link_id='77073' target_id='88'>letter</link> from 
<lb/><link target_title='John Brumfield' link_id='77074' target_id='209'>John</link> was glad to hear from 
<lb/>him and wish I could hear 
<lb/>from the rest of them.
</p><p>8 oclock</p>
      </page>
EOF

TRANSLATED_TEXT = <<AOI
    <?xml version="1.0" encoding="ISO-8859-15"?>
      <page>
        <p>Se almacenará un historial de <lb/>modificaciones para poder recuperar desde <lb/>una versión previa. </p>
      </page>
AOI


TAGS_TO_REMOVE = [
  "<?xml",
  "<page",
  "<p>",
  "<link",
  "<lb"
]

VERBATIM_MATCHES = [
  "I could not go", # uncomplicated
  "very rainy day", # spans link
  "I would go to see her", # spans linebreak
]

EXPANDED_MATCHES = [
  "Sam Owen",
  "Sally Joseph Carr"
]

TRANSLATED_MATCHES = [
  "modificaciones para",
  "almacenará",
  "desde una",
  "poder recuperar"  
]

describe "search text transformation" do
  search_text = SearchTranslator.search_text_from_xml(XML_TEXT, TRANSLATED_TEXT)
  
  it "should include text" do
    search_text.should match(/I could not go./)
  end
  
  it "should not include line breaks" do
    search_text.should match(/wish I could hear from the rest of them./)
  end
  
  it "should not include tags" do
    TAGS_TO_REMOVE.each do |tag|
      search_text.should_not match(tag)
    end
  end

  it "should not include wikilinks" do
    search_text.should_not include('[[')
  end
  
  it "should include verbatim transcripts" do
    VERBATIM_MATCHES.each do |search|
      search_text.should match(search)
    end
  end
  
  it "should include subject expansions" do
    EXPANDED_MATCHES.each do |search|
      search_text.should match(search)
    end  
  end
  
  it "should include translations" do
    TRANSLATED_MATCHES.each do |search|
      search_text.should match(search)
    end  
  end
end

describe "page post-processing"
