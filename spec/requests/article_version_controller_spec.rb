require 'spec_helper'

RSpec.describe ArticleVersionController do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:article) { create(:article, collection: collection, title: 'Current Article') }
  let!(:first_version) do
    create(:article_version, article: article, user: owner, title: 'Version 1', source_text: 'first', created_on: 2.days.ago)
  end
  let!(:second_version) do
    create(:article_version, article: article, user: owner, title: 'Version 2', source_text: 'second', created_on: 1.day.ago)
  end

  it 'lists article versions for an article' do
    get collection_article_version_path(owner, collection, article)

    expect(response).to have_http_status(:ok)
  end

  it 'uses the selected article version from params' do
    get article_version_list_path, params: { article_version_id: second_version.id }

    expect(response).to have_http_status(:ok)
  end
end
