require 'spec_helper'

describe CollectionController do
  before do
    User.current_user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:user) { create(:unique_user) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }

  describe '#search_users' do
    let(:action_path) { collection_search_users_path(collection_id: collection.slug) }
    let(:params) { { term: 'Search' } }

    let(:subject) { get action_path, params: params }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects' do
      login_as user
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    context 'when user_type owner' do
      let(:params) { { term: 'Search', user_type: 'owner' } }

      it 'renders status and json' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'when user_type blocked' do
      let(:params) { { term: 'Search', user_type: 'blocked' } }

      it 'renders status and json' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'when user_type reviewer' do
      let(:params) { { term: 'Search', user_type: 'reviewer' } }

      it 'renders status and json' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'when user_type collaborator (default)' do
      let(:params) { { term: 'Search' } }

      it 'renders status and json' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe '#edit' do
    let(:action_path) { edit_collection_path(owner, collection) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit)
    end
  end

  describe '#edit_tasks' do
    let!(:collection) { create(:collection, owner_user_id: owner.id, field_based: true, transcription_fields: []) }
    let(:action_path) { edit_tasks_collection_path(owner, collection) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_tasks)
    end
  end

  describe '#edit_look' do
    let(:action_path) { edit_look_collection_path(owner, collection) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_look)
    end
  end

  describe '#edit_privacy' do
    let!(:collaborator) do
      create(:user, email: "#{SecureRandom.base64(4)}@email.com", login: SecureRandom.base64(4).to_s)
    end
    let!(:noncollaborator) do
      create(:user, email: "#{SecureRandom.base64(4)}@email.com", login: SecureRandom.base64(4).to_s)
    end
    let!(:blocked_user) do
      create(:user, email: "#{SecureRandom.base64(4)}@email.com", login: SecureRandom.base64(4).to_s)
    end

    let!(:collection) do
      create(:collection, owner_user_id: owner.id, field_based: true, collaborators: [collaborator], blocked_users: [blocked_user])
    end
    let(:action_path) { edit_privacy_collection_path(owner, collection) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_privacy)
    end
  end

  describe '#edit_help' do
    let!(:collection) { create(:collection, owner_user_id: owner.id, transcription_conventions: 'Convention') }
    let(:action_path) { edit_help_collection_path(owner, collection) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_help)
    end

    context 'when one work with custom transcription convention' do
      let!(:work) { create(:work, collection: collection, owner_user_id: owner.id, transcription_conventions: 'Custom') }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit_help)
      end
    end

    context 'when more than one work with custom transcription convention' do
      let!(:works) do
        create_list(:work, 2, collection: collection, owner_user_id: owner.id, transcription_conventions: 'Custom')
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit_help)
      end
    end
  end

  describe '#edit_quality_control' do
    let!(:reviewer) do
      create(:user, email: "#{SecureRandom.base64(4)}@email.com", login: SecureRandom.base64(4).to_s)
    end
    let!(:collection) do
      create(:collection, owner_user_id: owner.id, field_based: true, reviewers: [reviewer])
    end
    let(:action_path) { edit_quality_control_collection_path(owner, collection) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_quality_control)
    end
  end

  describe '#edit_danger' do
    let(:action_path) { edit_danger_collection_path(owner, collection) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_danger)
    end
  end

  describe '#update' do
    let(:scope) { nil }
    let(:params) { {} }
    let(:action_path) { collection_update_path(collection.id, scope: scope) }

    let(:subject) { post action_path, params: params, as: :turbo_stream }

    context 'when scope edit' do
      let(:scope) { 'edit' }
      let(:params) { { collection: { title: 'New Collection Title' } } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_general)
      end
    end

    context 'when scope edit_tasks' do
      let(:scope) { 'edit_tasks' }
      let(:params) { { collection: { text_language: 'eng', field_based: true } } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_tasks)
      end
    end

    context 'when scope edit_look' do
      let(:scope) { 'edit_look' }
      let(:params) { { collection: { alphabetize_work: 'eng' } } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_look)
      end
    end

    context 'when scope edit_privacy' do
      let!(:collaborator) do
        create(:user, email: "#{SecureRandom.base64(4)}@email.com", login: SecureRandom.base64(4).to_s)
      end
      let!(:noncollaborator) do
        create(:user, email: "#{SecureRandom.base64(4)}@email.com", login: SecureRandom.base64(4).to_s)
      end
      let!(:blocked_user) do
        create(:user, email: "#{SecureRandom.base64(4)}@email.com", login: SecureRandom.base64(4).to_s)
      end

      let!(:collection) do
        create(:collection, owner_user_id: owner.id, field_based: true, collaborators: [collaborator], blocked_users: [blocked_user])
      end

      let(:scope) { 'edit_privacy' }
      let(:params) { { collection: { api_access: true } } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_privacy)
      end
    end

    context 'when scope edit_help' do
      let(:scope) { 'edit_help' }
      let(:params) { { collection: { transcription_conventions: '<b> New conventions </b>' } } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_help)
      end
    end

    context 'when scope edit_quality_control' do
      let(:scope) { 'edit_quality_control' }
      let(:params) { { collection: { review_type: 'optional' } } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_quality_control)
      end
    end

    context 'when scope edit_danger' do
      let(:scope) { 'edit_danger' }
      let(:params) { { collection: { is_active: false } } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_danger)
      end
    end
  end

  describe '#blank_collection' do
    let(:action_path) { collection_blank_collection_path(collection.id) }
    let(:subject) { post action_path }

    it 'redirects' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(collection_path(owner, collection))
    end
  end

  describe '#delete' do
    let(:action_path) { collection_delete_collection_path(collection.id) }
    let(:subject) { delete action_path }

    it 'redirects' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_owner_path)
    end
  end

  describe '#works_list' do
    let(:action_path) { collection_works_list_path(owner, collection) }
    let(:params) { {} }
    let(:subject) { get action_path, params: params }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:works_list)
    end

    context 'when accessed by non-owner user' do
      it 'redirects to collection show page' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_path(owner, collection))
      end
    end

    context 'when accessed by unauthenticated user' do
      it 'redirects to dashboard' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'with filters' do
      let(:work) { create(:work, collection: collection) }
      let(:subject) { get action_path, params: params, as: :turbo_stream }

      context 'search filter' do
        let(:params) { { search: work.title, order: 'ASC' } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:works_list)
        end
      end

      context 'show filter' do
        let(:params) { { show: 'need_transcription', order: 'DESC' } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:works_list)
        end
      end

      context 'sort by activity' do
        let(:params) { { sort: 'activity', order: 'ASC' } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:works_list)
        end
      end

      context 'sort by collaboration' do
        let(:params) { { sort: 'collaboration', order: 'DESC' } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:works_list)
        end
      end

      context 'per_page all' do
        let(:params) { { per_page: -1 } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:works_list)
        end
      end
    end
  end

  describe '#restrict_transcribed' do
    let!(:work) { create(:work, collection: collection) }
    let!(:work_statistic) { create(:work_statistic, work_id: work.id, complete: 100) }

    let(:action_path) { collection_restrict_transcribed_path(collection_id: collection) }

    subject { post action_path, as: :turbo_stream }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:restrict_transcribed)
    end

    context 'when document set' do
      let(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id, works: [work]) }

      let(:action_path) { collection_restrict_transcribed_path(collection_id: document_set) }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:restrict_transcribed)
      end
    end
  end

  describe '#search' do
    let!(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id, works: [work]) }
    let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
    let!(:page) { create(:page, work: work) }

    let(:action_path) { collection_search_path(owner, collection) }
    let(:params) { { term: page.title } }

    let(:subject) { get action_path, params: params }

    before do
      stub_const('ELASTIC_ENABLED', true)

      CollectionsIndex.import collection.reload
      DocumentSetsIndex.import document_set.reload
      WorksIndex.import collection.works
      PagesIndex.import collection.works.flat_map(&:pages)
    end

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:search)
    end

    context 'when document set' do
      let(:action_path) { collection_search_path(owner, document_set) }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:search)
      end
    end
  end
end
