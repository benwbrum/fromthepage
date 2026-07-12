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

  context 'when logged in' do
    before { login_as owner }

    it 'lists article versions for an article with robots noindex headers' do
      get collection_article_version_path(owner, collection, article)

      expect(response).to have_http_status(:ok)
      expect(response.headers['X-Robots-Tag']).to eq('noindex, nofollow, noarchive')
    end

    it 'uses the selected article version from params with robots noindex headers' do
      get article_version_list_path, params: { article_version_id: second_version.id }

      expect(response).to have_http_status(:ok)
      expect(response.headers['X-Robots-Tag']).to eq('noindex, nofollow, noarchive')
    end

    it 'uses robots noindex headers on direct article version show routes' do
      get article_version_show_path, params: { article_version_id: second_version.id }

      expect(response).to have_http_status(:ok)
      expect(response.headers['X-Robots-Tag']).to eq('noindex, nofollow, noarchive')
    end
  end

  context 'when logged out' do
    it 'redirects the collection article versions tab to sign in' do
      get collection_article_version_path(owner, collection, article)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects the direct article version list route to sign in' do
      get article_version_list_path, params: { article_version_id: second_version.id }

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects the direct article version show route to sign in' do
      get article_version_show_path, params: { article_version_id: second_version.id }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
