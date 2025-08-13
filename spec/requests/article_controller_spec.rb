require 'spec_helper'

describe ArticleController do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }
  let!(:category) { create(:category) }

  describe '#tooltip' do
    let!(:article) { create(:article, collection: collection, pages: [page], categories: [category]) }

    let(:action_path) { article_tooltip_path(article_id: article.id) }
    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(partial: 'article/_tooltip')
    end
  end

  describe '#list' do
    let!(:categorized_article) { create(:article, collection: collection, pages: [page], categories: [category]) }
    let!(:uncategorized_article) { create(:article, collection: collection, pages: [page]) }

    let(:action_path) { collection_subjects_path(owner, collection) }
    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:list)
    end
  end

  describe '#delete' do
    let!(:article) { create(:article, collection: collection) }

    let(:action_path) { article_delete_path(article_id: article.id, collection_id: collection.id) }
    let(:subject) { delete action_path }

    context 'not authorized' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'success' do
      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_subjects_path(owner, collection))
      end
    end
  end

  describe '#update' do
    let!(:article) { create(:article, collection: collection) }
    let(:params) { {} }

    let(:action_path) { collection_article_update_path(owner, collection, article) }
    let(:subject) { patch action_path, params: params }

    context 'not authorized' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    it 'redirects' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(collection_article_edit_path(owner, collection, article))
    end

    context 'when failed save' do
      let(:params) do
        {
          article: {
            title: ''
          },
          save: '1'
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
      end
    end

    context 'when successful save' do
      let(:params) do
        {
          article: {
            title: 'New title'
          },
          save: '1'
        }
      end

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_article_edit_path(owner, collection, article))
      end
    end

    context 'when autolink' do
      let(:params) do
        {
          autolink: '1'
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#assign_category' do
    let!(:article) { create(:article, collection: collection) }
    let(:params) do
      {
        category_ids: [category.id]
      }
    end

    let(:action_path) { article_article_category_path(article_id: article.id) }
    let(:subject) { post action_path, params: params, as: :turbo_stream }

    context 'not authorized' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:article_category)
    end
  end

  describe '#combine_duplicate' do
    let!(:from_article) { create(:article, collection: collection) }
    let!(:to_article) { create(:article, collection: collection) }
    let(:params) do
      {
        from_article_ids: [from_article.id],
      }
    end

    let(:action_path) { article_combine_duplicate_path(article_id: to_article.id) }
    let(:subject) { post action_path, params: params }

    context 'not authorized' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    it 'redirects' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(collection_article_edit_path(owner, collection, to_article))
    end

    context 'when no from_article_ids passed' do
      let(:params) { {} }

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_article_edit_path(owner, collection, to_article))
      end
    end

    context 'when from_article_ids passed does not exist' do
      let(:params) { { from_article_ids: ['non-existing-article-id'] } }

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_article_edit_path(owner, collection, to_article))
      end
    end
  end

  describe '#relationship_graph' do
    let!(:article) { create(:article, collection: collection, pages: [page]) }
    let!(:linked_article) { create(:article, collection: collection) }

    before do
      create(:article_article_link, source_article: article, target_article: linked_article)
      linked_article.pages << page
      FileUtils.rm_f(article.d3js_file)
    end

    let(:action_path) { collection_article_relationship_graph_path(owner, collection, article) }
    let(:subject) { get action_path }

    it 'returns graph data without authentication' do
      subject

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      node_ids = json['nodes'].map { |n| n['id'] }
      expect(node_ids).to include("S#{article.id}", "S#{linked_article.id}", "D#{page.id}")
      expect(json['links']).to include(a_hash_including('source' => "S#{article.id}", 'target' => "S#{linked_article.id}", 'group' => 'direct'))
      expect(File).to exist(article.d3js_file)
    end
  end
end
