require 'spec_helper'

RSpec.describe PageVersionController do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let(:page) { create(:page, work: work, title: 'Current page') }
  let!(:first_version) do
    create(:page_version, page: page, user: owner, title: 'Version 1', transcription: 'first', created_on: 2.days.ago)
  end
  let!(:second_version) do
    create(:page_version, page: page, user: owner, title: 'Version 2', transcription: 'second', created_on: 1.day.ago)
  end

  context 'when logged in' do
    before do
      login_as(owner, scope: :user)
    end

    it 'lists page versions for a page' do
      get collection_page_version_path(owner, collection, work, page)

      expect(response).to have_http_status(:ok)
    end

    it 'uses the requested comparison version' do
      get collection_page_version_path(owner, collection, work, page), params: { compare_version_id: first_version.id }

      expect(response).to have_http_status(:ok)
    end

    it 'uses the selected page version from params' do
      get page_version_list_path, params: { page_version_id: second_version.id }

      expect(response).to have_http_status(:ok)
    end
  end

  context 'when logged out' do
    it 'redirects the collection page versions tab to sign in' do
      get collection_page_version_path(owner, collection, work, page)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects the direct page version list route to sign in' do
      get page_version_list_path, params: { page_version_id: second_version.id }

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects the direct page version show route to sign in' do
      get page_version_show_path, params: { page_version_id: second_version.id }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'POST #revert' do
    let(:transcriber) { create(:unique_user) }

    context 'when logged in as owner' do
      before do
        login_as(owner, scope: :user)
      end

      it 'reverts the page to the selected version and redirects to transcription screen' do
        post page_version_revert_path, params: { page_version_id: first_version.id }

        expect(response).to redirect_to(collection_transcribe_page_path(owner, collection, work, page))
      end

      it 'updates the page source_text to match the reverted version' do
        post page_version_revert_path, params: { page_version_id: first_version.id }

        page.reload
        expect(page.source_text).to eq(first_version.transcription)
      end

      it 'updates the page title to match the reverted version' do
        post page_version_revert_path, params: { page_version_id: first_version.id }

        page.reload
        expect(page.title).to eq(first_version.title)
      end

      it 'sets a success flash notice' do
        post page_version_revert_path, params: { page_version_id: first_version.id }

        expect(flash[:notice]).to be_present
      end

      it 'keeps the current status when the selected version has no status' do
        post page_version_revert_path, params: { page_version_id: first_version.id }

        page.reload
        expect(page.status).to eq('new')
      end
    end

    context 'when logged in as a non-owner transcriber' do
      before do
        login_as(transcriber, scope: :user)
      end

      it 'denies access and redirects to the versions tab' do
        post page_version_revert_path, params: { page_version_id: first_version.id }

        expect(response).to redirect_to(collection_page_version_path(owner, collection, work, page))
      end

      it 'sets an error flash message' do
        post page_version_revert_path, params: { page_version_id: first_version.id }

        expect(flash[:error]).to be_present
      end

      it 'does not change the page content' do
        original_source_text = page.source_text
        post page_version_revert_path, params: { page_version_id: first_version.id }

        page.reload
        expect(page.source_text).to eq(original_source_text)
      end
    end

    context 'when logged out' do
      it 'redirects to sign in' do
        post page_version_revert_path, params: { page_version_id: first_version.id }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
