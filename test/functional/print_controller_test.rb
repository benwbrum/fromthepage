require File.dirname(__FILE__) + '/../test_helper'

class PrintControllerTest < ActionController::TestCase
  include PrintHelper
  @test_text = []

  def test_sees_helper
    setup_text
    #xml_to_latex("")
    assert true
  end

  def test_paras_have_double_linefeed
    setup_text
    # for each paragraph break test that it's replaced with \n\n
    p @test_text[0]
    assert_match /para\\n\\nAnother/, xml_to_latex(@test_text[0])
    assert_match /come\. *\\n\\nJosie/, xml_to_latex(@test_text[1])
    assert_match /sent it to day\. *\\n\\n9 30 oclock/, xml_to_latex(@test_text[1])
    assert_match /few days\. *\\n\\n8 oclock/, xml_to_latex(@test_text[2])
  end

  def test_no_tags
    setup_text
    @test_text.each do |text|
      latex = xml_to_latex(text)
      # line breaks
      assert_no_match /<lb/, latex
      # paragraphs
      assert_no_match /<p/, latex
      # xml
      assert_no_match /<\?xml/, latex
      # links
      assert_no_match /<link/, latex
      # anything else
      assert_no_match /</, latex
    end
  end

  # we want to convert links to footnotes if they have note contents, or if they're sufficiently expanded

  # we need to preserve state about links, only footnoting them on their first introduction




  def setup_text
    @test_text = []
    @test_text[0] =<<EOF
<?xml version='1.0' encoding='ISO-8859-15'?>
      <page>
        <p>A para</p><p>Another para</p>
      </page>
EOF

    @test_text[1] =<<EOF
<?xml version='1.0' encoding='ISO-8859-15'?>
      <page>
        <p>A <link link_id='36657' target_id='21' target_title='clear'>clear</link> day and some warmer.
<lb/><link link_id='36658' target_id='4' target_title='Benjamin Franklin Brumfield, Sr.'>Ben</link> has bin in the house all
<lb/>day but is some better off
<lb/>to day.  <link link_id='36659' target_id='9' target_title='Henry Anderson Brumfield'>Henry</link> is sick tonight.
<lb/>I got <link link_id='36660' target_id='26' target_title='breakfast'>breakfast</link> and <link link_id='36661' target_id='28' target_title='dinner'>dinner</link>.
<lb/><link link_id='36662' target_id='962' target_title='Sally Joseph Carr Brumfield'>Josie</link> got <link link_id='36663' target_id='71' target_title='supper'>supper</link>.  Would not
<lb/>have got any but <link link_id='36664' target_id='933' target_title='Walter Carr'>Mr Walter
<lb/>Carr</link> come.
</p><p>Josie <link link_id='36665' target_id='97' target_title='ironing'>ironed</link> some.  Josie <link link_id='36666' target_id='131' target_title='feeding'>fed</link> the
<lb/><link link_id='36667' target_id='133' target_title='horses'>horses</link> and <link link_id='36668' target_id='134' target_title='hogs'>hogs</link>.  I fed the <link link_id='36669' target_id='27' target_title='cows'>cows</link>.
<lb/><link link_id='36670' target_id='75' target_title='William Gilbert'>William Gilbert</link> come this morning
<lb/>and <link link_id='36671' target_id='135' target_title='wood splitting'>split</link> some <link link_id='36672' target_id='36' target_title='wood'>wood</link> for us.
<lb/><link link_id='36673' target_id='5' target_title='Marvin Smith'>Marvin</link> and <link link_id='36674' target_id='136' target_title='John Smith'>John Smith</link>
<lb/>went to <link link_id='36675' target_id='7208' target_title='Altavista, Virginia'>Altavista</link> to day.
<lb/><link link_id='36676' target_id='138' target_title='Mollie Reynolds'>Mollie Reynolds</link> come to <link link_id='36677' target_id='32' target_title='Carrie Smith'>Carries</link>
<lb/>today.  I got the <link link_id='36678' target_id='56' target_title='yarn'>yarn</link> to
<lb/><link link_id='36679' target_id='57' target_title='knitting'>knit</link> for <link link_id='36680' target_id='139' target_title='Bruce Sheppard'>Bruce Sheppard</link>
<lb/>sent it to day.
</p><p>9 30 oclock</p>
      </page>
EOF
    @test_text[2] =<<EOF
<?xml version='1.0' encoding='ISO-8859-15'?>
      <page>
        <p>A good day.  <link link_id='38002' target_id='4' target_title='Benjamin Franklin Brumfield, Sr.'>Ben</link> and
<lb/>family staid at home all
<lb/>day.  I was at <link link_id='38003' target_id='5' target_title='Marvin Smith'>Marvins</link>.
<lb/><link link_id='38004' target_id='32' target_title='Carrie Smith'>Carrie</link> has a little girl.
<lb/><link link_id='38005' target_id='53' target_title='Kate Harvey'>Kate Harvey</link> was at Marvins.
<lb/>They sent <link link_id='38006' target_id='190' target_title='Hazel'>Hazel</link> over to
<lb/>Kates this evening.
<lb/>She will take care of
<lb/>her a few days.
</p><p>8 oclock</p>
      </page>
EOF

  end

end
