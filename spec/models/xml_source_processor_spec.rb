require 'spec_helper'

SOURCE_TEXT = "With an [[Old Subject|old subject]] and a short [[Old Subject]]. With a [[New Text Link|new links]] and a [[New Short Text Link]]"
EXPECTED_XML = <<EOF.chomp
<?xml version='1.0' encoding='UTF-8'?>#{'    '}
      <page>
        <p>With an <link link_id='1' target_id='1' target_title='Old Subject'>old subject</link> and a short <link link_id='2' target_id='1' target_title='Old Subject'>Old Subject</link>. With a <link link_id='3' target_id='2' target_title='New Text Link'>new links</link> and a <link link_id='4' target_id='3' target_title='New Short Text Link'>New Short Text Link</link></p>
      </page>
EOF

EXPECTED_XML_DISABLED = <<EOF.chomp
<?xml version='1.0' encoding='UTF-8'?>#{'    '}
      <page>
        <p>With an [[Old Subject|old subject]] and a short [[Old Subject]]. With a [[New Text Link|new links]] and a [[New Short Text Link]]</p>
      </page>
EOF

SOURCE_TEXT_ILLEGAL_CHARS = "\fWith a lo\vad of illegal \u000C charac\u0014ters and a tab\t"
EXPECTED_XML_ILLEGAL_CHARS = <<EOF.chomp
<?xml version='1.0' encoding='UTF-8'?>#{'    '}
      <page>
        <p> With a lo ad of illegal   charac ters and a tab\t</p>
      </page>
EOF

RSpec.describe XmlSourceProcessor, type: :model do
  describe '#wiki_to_xml' do
  before :each do
    DatabaseCleaner.clean_with(:truncation)
  end

  let(:collection) { create(:collection) }
  let(:work)      { create(:work, collection: collection) }
  let(:page)      { create(:page, work: work, source_text: SOURCE_TEXT) }
  let(:old_link)  { build_stubbed(:article, title: 'Old Subject', collection: collection) }

    context 'subject linking not disabled (default)' do
      it 'builds the xml document' do
        expect(work.collection).to eq(collection)
        xml = page.wiki_to_xml(page, Page::TEXT_TYPE::TRANSCRIPTION)
        expect(Article.all.count).to eq(3)
        expect(PageArticleLink.all.count).to eq(4)
        expect(xml).to eq(EXPECTED_XML)
      end
    end
    context 'subject linking disabled' do
      it 'builds the xml document' do
        collection.subjects_disabled = true

        xml = page.wiki_to_xml(page, Page::TEXT_TYPE::TRANSCRIPTION)
        expect(xml).to eq(EXPECTED_XML_DISABLED)
        expect(Article.all.count).to eq(0)
        expect(PageArticleLink.all.count).to eq(0)
      end
    end
  end
  describe '#valid_xml_from_source' do
    let(:collection) { build_stubbed(:collection) }
    let(:work)      { build_stubbed(:work, collection: collection) }
    let(:page)      { build_stubbed(:page, work: work, source_text: SOURCE_TEXT_ILLEGAL_CHARS) }

    it 'builds the xml document' do
      expect(work.collection).to eq(collection)
      xml = page.wiki_to_xml(page, Page::TEXT_TYPE::TRANSCRIPTION)
      expect(xml).to eq(EXPECTED_XML_ILLEGAL_CHARS)
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
    let(:page_full_link_paren) do
      build_stubbed(:page, source_text: "[[Old Title (Parenthetical)|old title parenthetical]]")
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

    it 'should rename links that contained parentheses [[Old Title (Parenthetical)| old title parenthetical]]' do
      expected = "[[New Title|old title parenthetical]]"
      page_full_link_paren.rename_article_links('Old Title (Parenthetical)', 'New Title')
      expect(page_full_link_paren.source_text).to eq(expected)
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

  describe 'validation' do
    before :each do
      DatabaseCleaner.clean_with(:truncation)
    end

    let(:collection) { create(:collection) }
    let(:work) { create(:work, collection: collection) }

    # Text with unbalanced brackets that would normally cause validation errors
    let(:problematic_text) { 'MEDBREY[[SIC] and other [[ unbalanced brackets' }

    context 'regular collections' do
      let(:page) { build(:page, work: work, source_text: problematic_text) }

      it 'should validate subject linking syntax and add errors' do
        page.validate_source
        expect(page.errors).not_to be_empty
        expect(page.errors[:base]).to include(match(/Subject Linking Error/))
      end
    end

    context 'field-based collections' do
      let(:field_based_collection) { create(:collection, field_based: true) }
      let(:field_based_work) { create(:work, collection: field_based_collection) }
      let(:field_based_page) { build(:page, work: field_based_work, source_text: problematic_text) }

      it 'should skip subject linking validation' do
        field_based_page.validate_source
        expect(field_based_page.errors).to be_empty
      end
    end

    context 'collections with subjects disabled' do
      let(:subjects_disabled_collection) { create(:collection, subjects_disabled: true) }
      let(:subjects_disabled_work) { create(:work, collection: subjects_disabled_collection) }
      let(:subjects_disabled_page) { build(:page, work: subjects_disabled_work, source_text: problematic_text) }

      it 'should skip subject linking validation' do
        subjects_disabled_page.validate_source
        expect(subjects_disabled_page.errors).to be_empty
      end
    end

    context 'translation validation' do
      let(:field_based_collection) { create(:collection, field_based: true) }
      let(:field_based_work) { create(:work, collection: field_based_collection) }
      let(:field_based_page) { build(:page, work: field_based_work, source_translation: problematic_text) }

      it 'should skip subject linking validation for translations in field-based collections' do
        field_based_page.validate_source_translation
        expect(field_based_page.errors).to be_empty
      end
    end
  end

  describe '#process_linewise_markup table processing' do
    let(:collection) { build_stubbed(:collection) }
    let(:work) { build_stubbed(:work, collection: collection) }
    let(:page) { build_stubbed(:page, work: work) }

    it 'should handle tables with initial blank cells' do
      table_text = <<~TABLE
        Title | Author | Publisher
        --- | --- | ---
         | Steam and the Steam Engine | Crosby Lockwood & Co.
        Book Title | John Author | Some Publisher
      TABLE

      page.source_text = table_text
      result = page.process_linewise_markup(table_text)

      # The result should contain a table with an empty first cell in the first data row
      expect(result).to include('<table class="tabular">')
      expect(result).to include('<th>Title</th>')
      expect(result).to include('<th>Author</th>')
      expect(result).to include('<th>Publisher</th>')

      # Most importantly, the first data row should have an empty first cell
      expect(result).to include('<td></td> <td>Steam and the Steam Engine</td>')
      expect(result).to include('<td>Crosby Lockwood & Co.</td>')
    end

    it 'should handle single row table starting with blank cell' do
      table_text = " | Steam and the Steam Engine | Crosby Lockwood & Co.\n"

      page.source_text = table_text
      result = page.process_linewise_markup(table_text)

      # Should create a table with empty first header
      expect(result).to include('<table class="tabular">')
      expect(result).to include('<th></th>')
      expect(result).to include('<th>Steam and the Steam Engine</th>')
      expect(result).to include('<th>Crosby Lockwood & Co.</th>')
    end

    it 'should handle multiple initial blank cells' do
      table_text = " | | Third Column\n"

      page.source_text = table_text
      result = page.process_linewise_markup(table_text)

      # Should create a table with empty first and second headers
      expect(result).to include('<table class="tabular">')
      expect(result).to include('<th></th> <th></th>')
      expect(result).to include('<th>Third Column</th>')
    end

    it 'should preserve existing behavior for tables starting with pipe' do
      table_text = "| First | Second | Third\n"

      page.source_text = table_text
      result = page.process_linewise_markup(table_text)

      # Should work as before
      expect(result).to include('<table class="tabular">')
      expect(result).to include('<th>First</th>')
      expect(result).to include('<th>Second</th>')
      expect(result).to include('<th>Third</th>')
    end
  end
end
