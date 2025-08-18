require 'spec_helper'

describe Article::Combine do
  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
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

  let(:from_article_ids) { [from_article.id] }

  let(:result) do
    described_class.new(
      article: to_article,
      from_article_ids: from_article_ids,
      user: user
    ).call
  end

  it 'combines articles and updates source texts of related models' do
    expect(Article::RenameJob).to receive(:perform_later).with(
      user_id: user.id, article_id: from_article.id, old_name: 'Duplicate', new_name: 'Original', new_article_id: to_article.id
    ).and_call_original

    # Set source text like this to avoid before save callbacks
    from_source_article.update_column(:source_text, '[[Duplicate]]')

    expect(result.success?).to be_truthy
  end
end
