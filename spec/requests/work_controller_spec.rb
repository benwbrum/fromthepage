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

  describe '#edit_tasks' do
    let(:action_path) { edit_tasks_collection_work_path(owner, collection, work) }
    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit_tasks)
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

    context 'when scope tasks' do
      let(:scope) { 'edit_tasks' }

      let(:params) do
        {
          work: {
            collection_id: collection.id,
            supports_translation: true
          }
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_tasks)
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

  describe 'work metadata versions' do
    let!(:older_version) do
      create(
        :metadata_description_version,
        work: work,
        user: owner,
        version_number: 1,
        metadata_description: [{ 'label' => 'Date', 'value' => '1901' }].to_json
      )
    end
    let!(:current_version) do
      create(
        :metadata_description_version,
        work: work,
        user: owner,
        version_number: 2,
        metadata_description: [{ 'label' => 'Date', 'value' => '1902' }].to_json
      )
    end

    describe 'GET #description_versions' do
      it 'shows a restore button to an owner for a previous version' do
        login_as owner

        get description_versions_collection_work_path(
          owner,
          collection,
          work,
          metadata_description_version_id: older_version.id
        )

        rendered_page = Capybara.string(response.body)
        expect(rendered_page).to have_css(
          "form.diff-title-action input[type='submit'][value='Restore'][title='Replace the current work metadata with this version']"
        )
      end

      it 'does not show a restore button for the current version' do
        login_as owner

        get description_versions_collection_work_path(owner, collection, work)

        expect(response.body).not_to include('diff-title-action')
      end

      it 'does not show a restore button to a non-owner' do
        login_as create(:unique_user)

        get description_versions_collection_work_path(
          owner,
          collection,
          work,
          metadata_description_version_id: older_version.id
        )

        expect(response.body).not_to include('diff-title-action')
      end
    end

    describe 'PATCH #restore_description_version' do
      let(:action_path) do
        restore_description_version_collection_work_path(
          owner,
          collection,
          work,
          metadata_description_version_id: older_version.id
        )
      end

      it 'restores the selected metadata and records a new version for the owner' do
        login_as owner

        expect { patch action_path }.to change { work.metadata_description_versions.count }.by(1)

        expect(response).to redirect_to(describe_collection_work_path(owner, collection, work))
        expect(work.reload.metadata_description).to eq(older_version.metadata_description)
        expect(work.metadata_description_versions.first.user).to eq(owner)
        expect(flash[:notice]).to be_present
      end

      it 'does not allow a non-owner to restore metadata' do
        user = create(:unique_user)
        login_as user
        original_metadata = work.metadata_description

        patch action_path

        expect(response).to redirect_to(dashboard_path)
        expect(work.reload.metadata_description).to eq(original_metadata)
      end

      it 'does not restore a version belonging to another work' do
        other_work = create(:work, collection: collection, owner_user_id: owner.id)
        other_version = create(
          :metadata_description_version,
          work: other_work,
          user: owner,
          metadata_description: [{ 'label' => 'Date', 'value' => '1800' }].to_json
        )
        login_as owner

        patch restore_description_version_collection_work_path(
          owner,
          collection,
          work,
          metadata_description_version_id: other_version.id
        )

        expect(response).to redirect_to(description_versions_collection_work_path(owner, collection, work))
        expect(work.reload.metadata_description).not_to eq(other_version.metadata_description)
        expect(flash[:error]).to be_present
      end
    end
  end
end
