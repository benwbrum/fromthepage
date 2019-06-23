require 'spec_helper'

SOURCE_TEXT = "With an [[Old Subject|old subject]] and a short [[Old Subject]]. With a [[New Text Link|new links]] and a [[New Short Text Link]]"
EXPECTED_XML = <<EOF
<?xml version='1.0' encoding='UTF-8'?>    
      <page>
        <p>With an <link link_id='1' target_id='1' target_title='Old Subject'>old subject</link> and a short <link link_id='2' target_id='1' target_title='Old Subject'>Old Subject</link>. With a <link link_id='3' target_id='2' target_title='New Text Link'>new links</link> and a <link link_id='4' target_id='3' target_title='New Short Text Link'>New Short Text Link</link></p>
      </page>
EOF

EXPECTED_XML_DISABLED = <<EOF
<?xml version='1.0' encoding='UTF-8'?>    
      <page>
        <p>With an [[Old Subject|old subject]] and a short [[Old Subject]]. With a [[New Text Link|new links]] and a [[New Short Text Link]]</p>
      </page>
EOF

RSpec.describe XmlSourceProcessor, type: :model do
  describe '#wiki_to_xml' do
  
  before :each do
    DatabaseCleaner.clean_with(:truncation)
  end

  let(:collection){ build_stubbed(:collection ) }
  let(:work)      { build_stubbed(:work, collection: collection) }
  let(:page)      { build_stubbed(:page, work: work)}
  let(:old_link)  { build_stubbed(:article, title: 'Old Subject', collection: collection ) }
    
    context 'subject linking not disabled (default)' do
      it 'builds the xml document' do
        expect(work.collection).to eq(collection)
        xml = page.wiki_to_xml(SOURCE_TEXT, Page::TEXT_TYPE::TRANSCRIPTION)
        expect(Article.all.count).to eq(3)
        expect(PageArticleLink.all.count).to eq(4)
        expect(xml).to eq(EXPECTED_XML)
      end
    end
    context 'subject linking disabled' do
      it 'builds the xml document' do
        expect(work.collection).to eq(collection)
        xml = page.wiki_to_xml(SOURCE_TEXT, Page::TEXT_TYPE::TRANSCRIPTION, true)
        expect(xml).to eq(EXPECTED_XML_DISABLED)
        expect(Article.all.count).to eq(0)
        expect(PageArticleLink.all.count).to eq(0)
      end
    end
  end
  describe '#rename_article_links' do
    let(:page_full_link) do
      build_stubbed(
        :page, source_text: '[[Old Title|old title verbatim]]',
              source_translation: '[[Old Translation|old translation verbatim]]'
      )
    end
    let(:page_short_link) do
      build_stubbed(:page, source_text: '[[Old Title]]')
    end

    let(:page_full_link_newline) do
      build_stubbed(:page, source_text: "[[Old\nTitle|old title\nverbatim]]")
    end
    let(:page_short_link_newline) do
      build_stubbed(:page, source_text: "[[Old\nTitle]]")
    end
    let(:page_multilink) do
      build_stubbed(:page, source_text: "[[Old Title]][[Unchanged]]")
    end
    it 'should rename links in the format [[Title|verbatim]]' do
      expected = '[[New Title|old title verbatim]]'
      page_full_link.rename_article_links('Old Title', 'New Title')
      expect(page_full_link.source_text).to eq(expected)
    end

    it 'should rename links in the format [[Title]]' do
      expected = '[[New Title|Old Title]]'
      page_short_link.rename_article_links('Old Title', 'New Title')
      expect(page_short_link.source_text).to eq(expected)
    end

    it 'should rename links that contained newlines like [[Old Title| old title\nverbatim]]' do
      expected = "[[New Title|old title\nverbatim]]"
      page_full_link_newline.rename_article_links('Old Title', 'New Title')
      expect(page_full_link_newline.source_text).to eq(expected)
    end

    it 'should rename links that contained newlines like [[New\nline]]' do
      # Titles are always sanitized in their canonical form, so the search
      # 'Old Title' will always use ' ' rather than '\n'.
      expected = "[[New Title|Old\nTitle]]"
      page_short_link_newline.rename_article_links('Old Title', 'New Title')
      expect(page_short_link_newline.source_text).to eq(expected)
    end

    it 'should rename links in both transcription and translation texts' do
      expected = '[[New Translation|old translation verbatim]]'
      page_full_link.rename_article_links('Old Translation', 'New Translation')
      expect(page_full_link.source_translation).to eq(expected)
    end
    it 'should only change links containing Old Title' do
      expected = '[[New Title|Old Title]][[Unchanged]]'
      page_multilink.rename_article_links('Old Title', 'New Title')
      expect(page_multilink.source_text).to eq(expected)
    end
  end
end
