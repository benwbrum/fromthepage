# frozen_string_literal: true

require 'spec_helper'
require 'search_translator'

describe 'search text transformation' do
  subject(:search_text) { SearchTranslator.search_text_from_xml(xml_text, translated_text) }

  let(:xml_text) do
    <<~XML
      <?xml version='1.0' encoding='ISO-8859-15'?>
      <page>
        <p>A very <link target_title='rain' link_id='77064' target_id='49'>rainy</link> day the children
        <lb/>did not go to <link target_title='school' link_id='77065' target_id='254'>school</link>.
        <link target_title='Benjamin Franklin Brumfield, Sr.' link_id='77066' target_id='4'>Ben</link> worked
        <lb/>on <link target_title='Sam Owen' link_id='77067' target_id='188'>Owens</link>
        <link target_title='tenant house' link_id='77068' target_id='181'>house</link>.</p>
        <p><link target_title='Sally Joseph Carr Brumfield' link_id='77069' target_id='1627'>Josie</link> &amp;
        <link target_title='sewing' link_id='77070' target_id='29'>sewed</link> a little
        <lb/>today was <link target_title='Carrie Smith' link_id='77071' target_id='32'>Carries</link> birth day.
        <lb/>I had thought I would go
        <lb/>to see her but it <link target_title='rain' link_id='77072' target_id='49'>rained</link>
        <lb/>so that I could not go.
        <lb/>I had a <link target_title='letter' link_id='77073' target_id='88'>letter</link> from
        <lb/><link target_title='John Brumfield' link_id='77074' target_id='209'>John</link> was glad to hear from
        <lb/>him and wish I could hear
        <lb/>from the rest of them.</p>
        <p>8 oclock</p>
      </page>
    XML
  end

  let(:translated_text) do
    <<~XML
      <?xml version="1.0" encoding="ISO-8859-15"?>
      <page>
        <p>Se almacenará un historial de <lb/>modificaciones para poder recuperar desde
        <lb/>una versión previa.</p>
      </page>
    XML
  end

  it 'includes transcript text' do
    expect(search_text).to match(/I could not go./)
  end

  it 'normalizes line breaks' do
    expect(search_text).to match(/wish I could hear from the rest of them./)
  end

  it 'removes XML tags' do
    ['<?xml', '<page', '<p>', '<link', '<lb'].each do |tag|
      expect(search_text).not_to include(tag)
    end
  end

  it 'does not introduce wikilinks' do
    expect(search_text).not_to include('[[')
  end

  it 'includes verbatim transcript phrases' do
    ['I could not go', 'very rainy day', 'I would go to see her'].each do |phrase|
      expect(search_text).to include(phrase)
    end
  end

  it 'includes canonical subject titles' do
    ['Sam Owen', 'Sally Joseph Carr'].each do |subject_title|
      expect(search_text).to include(subject_title)
    end
  end

  it 'includes translated phrases' do
    ['modificaciones para', 'almacenará', 'desde una', 'poder recuperar'].each do |phrase|
      expect(search_text).to include(phrase)
    end
  end
end
