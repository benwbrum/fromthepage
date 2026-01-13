require 'spec_helper'

describe ArticleController do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }
  let!(:category) { create(:category, collection_id: collection.id) }

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
    let!(:child_category) { create(:category, collection_id: collection.id, parent_id: category.id) }
    let!(:empty_category) { create(:category, collection_id: collection.id) }
    let!(:categorized_article) { create(:article, collection: collection, pages: [page], categories: [category]) }
    let!(:uncategorized_article) { create(:article, collection: collection, pages: [page]) }

    let(:params) { {} }
    let(:action_path) { collection_subjects_path(owner, collection) }
    let(:subject) { get action_path, params: params }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:list)
    end

    context 'filters' do
      let(:subject) { get action_path, params: params, as: :turbo_stream }

      context 'when page_id param present' do
        let(:params) { { page_id: page.id } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:list)
        end
      end

      context 'when selecting child category' do
        let(:params) { { selected_category_id: child_category.id } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:list)
        end
      end

      context 'when selecting category' do
        let(:params) { { selected_category_id: category.id } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:list)
        end
      end

      context 'when selecting empty category' do
        let(:params) { { selected_category_id: empty_category.id } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:list)
        end
      end

      context 'when selecting uncategorized' do
        let(:params) { { selected_category_id: 'uncategorized' } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:list)
        end
      end

      context 'when document_set' do
        let!(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id) }
        let(:action_path) { collection_subjects_path(owner, document_set) }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:list)
        end
      end
    end
  end

  describe '#items' do
    let!(:child_category) { create(:category, collection_id: collection.id, parent_id: category.id) }
    let!(:empty_category) { create(:category, collection_id: collection.id) }
    let!(:categorized_article) { create(:article, collection: collection, pages: [page], categories: [category]) }
    let!(:uncategorized_article) { create(:article, collection: collection, pages: [page]) }

    let(:selected_category_id) { category.id }
    let(:params) do
      {
        batch: 0,
        timestamp: Time.now.to_i,
        selected_category_id: selected_category_id
      }
    end

    let(:action_path) { article_items_path(collection_id: collection.slug) }
    let(:subject) { get action_path, params: params }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:_items)
    end

    context 'when uncategorized' do
      let(:selected_category_id) { 'uncategorized' }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:_items)
      end
    end

    context 'with next batch' do
      let!(:other_articles) { create_list(:article, 3, collection: collection, pages: [page], categories: [category]) }
      before do
        stub_const('ArticleController::ARTICLES_BATCH_SIZE', 3)
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:_items)
      end
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
        from_article_ids: [from_article.id]
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

  describe '#show' do
    let!(:article) { create(:article, collection: collection, pages: [page]) }

    context 'when article_id is missing' do
      let(:action_path) { article_show_path }
      let(:subject) { get action_path }

      it 'returns bad request status' do
        subject

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when article_id is provided' do
      let(:action_path) { article_show_path(article_id: article.id) }
      let(:subject) { get action_path }

      it 'renders successfully' do
        subject

        expect(response).to have_http_status(:ok)
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

    it 'excludes bio field from article nodes in JSON response' do
      subject

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # Find article nodes (not document nodes)
      article_nodes = json['nodes'].select { |n| n['id'].start_with?('S') }

      # Verify that no article nodes contain bio field
      article_nodes.each do |node|
        expect(node).not_to have_key('bio')
      end
    end

    it 'includes identifier in document nodes' do
      subject

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # Find document nodes (not article nodes)
      document_nodes = json['nodes'].select { |n| n['id'].start_with?('D') }

      # Verify that all document nodes contain identifier field
      expect(document_nodes).not_to be_empty
      document_nodes.each do |node|
        expect(node).to have_key('identifier')
        expect(node['identifier']).to eq(work.identifier)
      end
    end

    context 'when pages_are_not_meaningful' do
      let!(:work_not_meaningful) { create(:work, collection: collection, owner_user_id: owner.id, pages_are_meaningful: false) }
      let!(:page_not_meaningful) { create(:page, work: work_not_meaningful) }
      let!(:article_in_work) { create(:article, collection: collection) }

      before do
        create(:page_article_link, article: article_in_work, work: work_not_meaningful, page: page_not_meaningful)
        FileUtils.rm_f(article_in_work.d3js_file)
      end

      it 'includes identifier in work-based document nodes' do
        get collection_article_relationship_graph_path(owner, collection, article_in_work)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        # Find document nodes (not article nodes)
        document_nodes = json['nodes'].select { |n| n['id'].start_with?('D') }

        # Verify that all document nodes contain identifier field
        expect(document_nodes).not_to be_empty
        document_nodes.each do |node|
          expect(node).to have_key('identifier')
          expect(node['identifier']).to eq(work_not_meaningful.identifier)
        end
      end
    end
  end

  describe '#upload_form' do
    let(:action_path) { article_upload_form_path(collection) }
    let(:subject) { get action_path }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    context 'when no access' do
      let!(:collection) { create(:collection, owner_user_id: owner.id, restricted: true) }
      let!(:non_owner) { create(:unique_user) }

      it 'redirects' do
        login_as non_owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(user_profile_path(owner))
      end
    end

    context 'with access' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:upload_form)
      end
    end
  end

  describe '#subject_upload' do
    let(:action_path) { article_subject_upload_path(collection_id: collection.slug) }

    let(:file_path) { Rails.root.join('test_data/imports/subject_upload.csv') }
    let(:file_type) { 'text/csv' }
    let(:params) do
      {
        upload: {
          file: Rack::Test::UploadedFile.new(file_path, file_type)
        }
      }
    end
    let(:subject) { post action_path, params: params }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    context 'when no access' do
      let!(:collection) { create(:collection, owner_user_id: owner.id, restricted: true) }
      let!(:non_owner) { create(:unique_user) }

      it 'redirects' do
        login_as non_owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(user_profile_path(owner))
      end
    end

    context 'with access' do
      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_subjects_path(owner, collection))
      end

      context 'incomplete headers' do
        let(:file_path) { Rails.root.join('test_data/imports/wrong_subject_upload.csv') }

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(article_upload_form_path(collection))
        end
      end
    end
  end
end
