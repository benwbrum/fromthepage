require 'spec_helper'

describe WorkController do
  before do
    Current.user = owner
  end

  let(:owner) { User.find_by(owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }
  let!(:article) { create(:article, collection: collection, pages: [page]) }

  describe '#edit' do
    let(:action_path) { edit_collection_work_path(owner, collection, work) }
    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit)
    end

    context 'when user is not logged in' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user is not an owner' do
      let(:user) { User.where(owner: false).first }

      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe '#edit_metadata' do
    let(:action_path) { edit_metadata_collection_work_path(owner, collection, work) }
    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_metadata)
    end

    context 'when user is not logged in' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user is not an owner' do
      let(:user) { User.where(owner: false).first }

      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe '#edit_privacy' do
    let(:action_path) { edit_privacy_collection_work_path(owner, collection, work) }
    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_privacy)
    end

    context 'when user is not logged in' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user is not an owner' do
      let(:user) { User.where(owner: false).first }

      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe '#edit_danger' do
    let(:action_path) { edit_danger_collection_work_path(owner, collection, work) }
    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_danger)
    end

    context 'when user is not logged in' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'when user is not an owner' do
      let(:user) { User.where(owner: false).first }

      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe '#update' do
    let(:scope) { nil }
    let(:params) { {} }
    let(:action_path) { work_update_path(id: work.id, scope: scope) }

    let(:subject) { post action_path, params: params, as: :turbo_stream }

    context 'when scope edit' do
      let(:scope) { 'edit' }

      let(:params) do
        {
          work: {
            title: 'New title',
            description: '<b> New description </b>',
            collection_id: collection.id,
            transcription_conventions: 'New transcription conventions'
          }
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_general)
      end

      context 'when changed collection_id' do
        let!(:collection_2) { create(:collection, owner_user_id: owner.id) }
        let(:params) do
          {
            work: {
              title: 'New title',
              description: '<b> New description </b>',
              collection_id: collection_2.id,
              transcription_conventions: 'New transcription conventions'
            }
          }
        end

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:update_general)
        end
      end

      context 'failed update' do
        let(:params) do
          {
            work: {
              title: '',
              description: ''
            }
          }
        end

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:update_general)
        end
      end
    end

    context 'when scope metadata' do
      let(:scope) { 'edit_metadata' }

      let(:params) do
        {
          work: {
            collection_id: collection.id,
            author: 'Author'
          }
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_metadata)
      end
    end

    context 'when scope privacy' do
      let(:scope) { 'edit_privacy' }

      let(:params) do
        {
          work: {
            collection_id: collection.id,
            scribes_can_edit_title: true
          }
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_privacy)
      end
    end
  end

  describe '#search' do
    let(:action_path) { collection_work_search_path(owner, collection, work) }
    let(:params) { { term: page.title } }

    let(:subject) { get action_path, params: params }

    before do
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

      stub_const('ELASTIC_ENABLED', true)

      CollectionsIndex.import collection.reload
      WorksIndex.import collection.works
      PagesIndex.import collection.works.flat_map(&:pages)
    end

    after do
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
    end

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:search)
    end
  end
end
