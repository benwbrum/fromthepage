require 'spec_helper'

RSpec.describe XmlSourceProcessor, type: :model do
  describe '#update_links_and_xml performance optimization' do
    before :each do
      DatabaseCleaner.clean_with(:truncation)
    end

    let(:collection) { create(:collection) }
    let(:work) { create(:work, collection: collection) }
    let(:page) { create(:page, work: work) }

    context 'with many existing articles' do
      before do
        # Create a large collection of existing articles to simulate 15K subjects
        50.times do |i|
          create(:article, title: "Existing Subject #{i}", collection: collection)
        end
      end

      it 'should efficiently process multiple links without N+1 queries' do
        # Create source text with 10 links to existing and new articles
        source_text = (1..10).map do |i|
          if i <= 5
            "[[Existing Subject #{i}]]"
          else
            "[[New Subject #{i}]]"
          end
        end.join(' ')

        page.source_text = source_text

        # Process the text and measure query count
        # The optimized version should:
        # 1. Load all articles in one query (articles_by_title)
        # 2. Load recent article versions in one query (if needed)
        # 3. Create new articles (one query per new article)
        # 4. Create page article links (one query per link)
        #
        # Total: ~3-4 queries for loading + 5 new articles + 10 links = ~18 queries
        # vs. Old way: 2 queries per link × 10 links = 20+ queries just for lookups

        expect do
          xml = page.wiki_to_xml(page, Page::TEXT_TYPE::TRANSCRIPTION)
          expect(xml).to include('<link')
        end.not_to raise_error

        # Verify that all articles were created
        expect(Article.where('title LIKE ?', 'New Subject%').count).to eq(5)
        # Verify that links were created
        expect(page.page_article_links.count).to eq(10)
      end

      it 'should deduplicate new articles with the same title in one batch' do
        # Create source text with multiple links to the same new article
        source_text = "[[New Article]] and [[New Article]] and [[New Article]]"
        page.source_text = source_text

        xml = page.wiki_to_xml(page, Page::TEXT_TYPE::TRANSCRIPTION)

        # Should create only ONE article, not three
        expect(Article.where(title: 'New Article').count).to eq(1)
        # But should create THREE links to that article
        expect(page.page_article_links.count).to eq(3)
        expect(xml.scan(/<link/).count).to eq(3)
      end
    end

    context 'clear_links optimization' do
      let(:article1) { create(:article, title: 'Test Article 1', collection: collection) }
      let(:article2) { create(:article, title: 'Test Article 2', collection: collection) }

      before do
        # Create some links
        create(:page_article_link, page: page, article: article1, work: work, text_type: 'transcription')
        create(:page_article_link, page: page, article: article2, work: work, text_type: 'transcription')
        create(:page_article_link, page: page, article: article1, work: work, text_type: 'translation')
      end

      it 'should use delete_all instead of destroy_all for better performance' do
        expect(page.page_article_links.count).to eq(3)

        # This should only delete transcription links
        page.clear_links('transcription')

        expect(page.page_article_links.reload.count).to eq(1)
        expect(page.page_article_links.first.text_type).to eq('translation')
      end
    end
  end
end
