require 'spec_helper'

describe Article::Destroy do
  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }
  let!(:article) { create(:article, collection: collection) }

  let(:result) do
    described_class.call(
      article: article,
      user: user,
      collection: collection
    )
  end

  context 'with referring links' do
    let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
    let!(:page) { create(:page, work: work) }
    let!(:article) { create(:article, collection: collection, pages: [page]) }

    it 'fails to delete' do
      expect(result.success?).to be_falsey
      expect(result.message).to eq(I18n.t('article.delete.must_remove_referring_links'))
    end
  end

  context 'when user is not owner' do
    let!(:other_user) { create(:unique_user) }

    let(:result) do
      described_class.call(
        article: article,
        user: other_user,
        collection: collection
      )
    end

    it 'fails to delete' do
      expect(result.success?).to be_falsey
      expect(result.message).to eq(I18n.t('article.delete.only_subject_owner_can_delete'))
    end
  end

  it 'deletes article' do
    expect(result.success?).to be_truthy
    expect(result.article.destroyed?).to be_truthy
  end
end
