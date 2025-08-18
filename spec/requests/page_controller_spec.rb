require 'spec_helper'

describe PageController do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, :with_image, work: work, status: :new) }

  describe '#new' do
    let(:action_path) { new_page_path(work_id: work.id) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
    end
  end

  describe '#create' do
    let(:action_path) { page_index_path }

    let(:file_path) { Rails.root.join('test_data/images/pages/sanskrit.jpg') }
    let(:file_type) { 'image/jpeg' }
    let(:page_params) do
      {
        title: 'Page title',
        base_image: Rack::Test::UploadedFile.new(file_path, file_type)
      }
    end
    let(:subaction) { '' }
    let(:params) do
      { work_id: work.id, page: page_params, subaction: subaction }
    end

    let(:subject) { post action_path, params: params }

    context 'correct params' do
      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(
          work_pages_tab_path(work_id: work.id, anchor: 'create-page')
        )
      end

      context 'with subaction' do
        let(:subaction) { 'save_and_new' }

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            dashboard_startproject_path(anchor: 'create-work')
          )
        end
      end
    end

    context 'incorrect params' do
      let(:file_path) { Rails.root.join('test_data/transcripts/sanskrit.txt') }
      let(:file_type) { 'text/plain' }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#edit' do
    let(:action_path) do
      collection_edit_page_path(owner, collection, work, page.id)
    end

    let(:subject) { get action_path }

    context 'user not logged in' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'user not owner' do
      let(:unique_id) { Time.current.to_i }
      let(:user) do
        create(
          :user,
          login: "user_#{unique_id}",
          email: "user_#{unique_id}@sample.com"
        )
      end

      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'user is owner' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    let(:action_path) { page_path(page) }

    let(:file_path) { Rails.root.join('test_data/images/pages/sanskrit.jpg') }
    let(:file_type) { 'image/jpeg' }
    let(:params) do
      {
        page: {
          title: 'Page title',
          base_image: Rack::Test::UploadedFile.new(file_path, file_type)
        }
      }
    end

    let(:subject) { put action_path, params: params, as: :turbo_stream }

    context 'correct params' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_general)
      end
    end

    context 'incorrect params' do
      let(:file_path) { Rails.root.join('test_data/transcripts/sanskrit.txt') }
      let(:file_type) { 'text/plain' }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:update_general)
      end
    end
  end

  describe '#destroy' do
    let(:action_path) { page_path(page) }

    let(:subject) { delete action_path }

    it 'redirects' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(work_pages_tab_path(work_id: work.id))
    end
  end

  describe '#rotate' do
    let(:action_path) { rotate_page_index_path }
    let(:params) { { page_id: page.id, orientation: 90 } }

    let(:subject) { post action_path, params: params }

    it 'redirects' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(page)
    end

    context 'no orientation param' do
      let(:params) { { page_id: page.id } }

      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(page)
      end
    end
  end

  describe '#reorder' do
    let(:action_path) { reorder_page_index_path }
    let(:params) { { page_id: page.id, direction: 'up' } }

    let(:subject) { post action_path, params: params }

    it 'redirects' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(work_pages_tab_path(work_id: work.id))
    end
  end
end
