require 'spec_helper'

describe Article::Destroy do
  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
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

  let(:result) do
    described_class.new(
      article: article,
      user: user,
      collection: collection
    ).call
  end

  context 'when user is not owner' do
    let!(:other_user) { create(:unique_user) }

    let(:result) do
      described_class.new(
        article: article,
        user: other_user,
        collection: collection
      ).call
    end

    it 'fails to delete' do
      expect(result.success?).to be_falsey
      expect(result.message).to eq(I18n.t('article.delete.only_subject_owner_can_delete'))
    end
  end


  it 'deletes articles and enqueues rename job' do
    expect(Article::RenameJob).to receive(:perform_later).with(
      article_id: article.id, old_name: 'Original', new_name: ''
    ).and_call_original

    expect(result.success?).to be_truthy
    expect(result.article.destroyed?).to be_truthy
  end

end
