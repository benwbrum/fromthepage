require 'spec_helper'

RSpec.describe TranscribeHelper, type: :model do
  let(:page_full_link) do
    FactoryBot.build_stubbed(
      :page, source_text: '[[Old Title|old title verbatim]]',
             source_translation: '[[Old Translation|old translation verbatim]]'
    )
  end
  let(:page_short_link) do
    FactoryBot.build_stubbed(:page, source_text: '[[Old Title]]')
  end

  let(:page_full_link_newline) do
    FactoryBot.build_stubbed(:page, source_text: "[[Old\nTitle|old title\nverbatim]]")
  end
  let(:page_short_link_newline) do
    FactoryBot.build_stubbed(:page, source_text: "[[Old\nTitle]]")
  end
  let(:page_multilink) do
    FactoryBot.build_stubbed(:page, source_text: "[[Old Title]][[Unchanged]]")
  end
  describe '#rename_article_links' do
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
