require 'spec_helper'

describe Article::RenameJob do
  include ActiveJob::TestHelper

  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }

  subject(:worker) { described_class.new }

  context 'from update' do
    let!(:related_page) { create(:page, work: work, source_text: '[[Original]]', source_translation: '[[Original]]') }
    let!(:article) do
      create(:article, title: 'New', collection: collection, pages: [related_page])
    end

    let!(:source_article) do
      create(:article, collection: collection.reload)
    end
    let!(:article_article_link) do
      create(:article_article_link, source_article: source_article, target_article: article)
    end

    let(:perform_worker) do
      worker.perform(article_id: article.id, old_name: 'Original', new_name: 'New')
    end

    it 'updates source texts of related models' do
      # Set source text like this to avoid before save callbacks
      source_article.update_column(:source_text, '[[Original]]')

      perform_enqueued_jobs do
        perform_worker
      end

      expect(article.reload).to have_attributes(title: 'New')
      expect(related_page.reload).to have_attributes(
        source_text: '[[New|Original]]',
        source_translation: '[[New|Original]]'
      )
      expect(source_article.reload).to have_attributes(source_text: '[[New|Original]]')
      expect(article.categories.any?).to be_falsey
    end
  end

  context 'from combine' do
    let!(:from_related_page) do
      create(:page, work: work, source_text: '[[Duplicate]]', source_translation: '[[Duplicate]]')
    end
    let!(:from_source_article) do
      create(:article, collection: collection.reload)
    end
    let!(:from_article) do
      create(:article, title: 'Duplicate', source_text: 'appended text', collection: collection,
                       pages: [from_related_page])
    end
    let!(:article_article_link) do
      create(:article_article_link, source_article: from_source_article, target_article: from_article)
    end
    let!(:from_deed) { create(:deed, deed_type: DeedType::ARTICLE_EDIT, article_id: from_article.id, user_id: user.id) }

    let!(:to_article) do
      create(:article, title: 'Original', source_text: 'To have ', collection: collection)
    end

    let(:perform_worker) do
      worker.perform(article_id: from_article.id, old_name: 'Duplicate', new_name: 'Original',
                     new_article_id: to_article.id)
    end

    it 'combines articles and updates source texts of related models' do
      # Set source text like this to avoid before save callbacks
      from_source_article.update_column(:source_text, '[[Duplicate]]')

      perform_enqueued_jobs do
        perform_worker
      end

      expect(Article.exists?(from_article.id)).to be_falsey
      expect(from_related_page.reload).to have_attributes(
        source_text: '[[Original|Duplicate]]',
        source_translation: '[[Original|Duplicate]]'
      )
      expect(from_source_article.reload).to have_attributes(source_text: '[[Original|Duplicate]]')
      expect(to_article.reload).to have_attributes(source_text: 'To have appended text')
      expect(from_deed.reload).to have_attributes(article_id: to_article.id)
    end
  end

  context 'from destroy' do
    let!(:related_page) { create(:page, work: work, source_text: '[[Original]]', source_translation: '[[Original]]') }
    let!(:article) do
      create(:article, title: 'Original', collection: collection, pages: [related_page])
    end

    let!(:source_article) do
      create(:article, collection: collection.reload)
    end
    let!(:article_article_link) do
      create(:article_article_link, source_article: source_article, target_article: article)
    end

    let(:perform_worker) do
      worker.perform(article_id: article.id, old_name: 'Original', new_name: '')
    end

    it 'removes links in texts and delets article links' do
      # Set source text like this to avoid before save callbacks
      source_article.update_column(:source_text, '[[Original]]')

      article.destroy!

      perform_enqueued_jobs do
        perform_worker
      end

      expect(related_page.reload).to have_attributes(
        source_text: 'Original',
        source_translation: 'Original'
      )
      expect(source_article.reload).to have_attributes(source_text: 'Original')
      expect(ArticleArticleLink.exists?(article_article_link.id)).to be_falsey
    end
  end
end
