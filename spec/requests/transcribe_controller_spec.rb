require 'spec_helper'

describe TranscribeController do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  describe '#display_page' do
    let(:action_path) { collection_transcribe_page_path(owner, collection, work, page) }
    let(:subject) { get action_path }

    context 'when user is not logged in' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when collection is inactive' do
      let!(:user) { create(:unique_user) }

      before do
        collection.update!(is_active: false)
      end

      it 'redirects to collection overview instead of display page' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_path(owner, collection))
      end
    end

    context 'when read-only document set and user is not a collaborator' do
      let!(:document_set) { create(:document_set, :read_only, owner_user_id: owner.id, collection_id: collection.id) }
      let!(:user) { create(:unique_user) }
      let(:action_path) { collection_transcribe_page_path(owner, document_set, work, page) }

      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_display_page_path(owner, document_set, work, page))
      end
    end

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:display_page)
    end
  end

  describe '#help' do
    let(:action_path) { collection_help_page_path(owner, collection, work, page) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:help)
    end
  end

  describe '#mark_page_blank' do
    let(:action_path) { transcribe_mark_page_blank_path(page_id: page.id) }

    let(:subject) { post action_path, as: :turbo_stream }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:mark_page_blank)
    end
  end

  # TODO: Full test suite for save_transcription
  # For now, we cover the branch for mark_blank logic
  describe '#save_transcription' do
    let(:action_path) { transcribe_save_transcription_path }
    let(:params) { {} }

    let(:subject) { patch action_path, params: params }

    context 'mark_blank_logic' do
      let!(:search_attempt) do
        create(:search_attempt, user_id: owner.id, search_type: 'findaproject', query: page.title)
      end
      let(:params) do
        {
          page_id: page.id,
          page: {
            mark_blank: '1'
          }
        }
      end

      before do
        allow(Current).to receive(:session).and_return({ search_attempt_id: search_attempt.id })
      end

      context 'when non-blank page is set to blank and there is next page' do
        let!(:next_page) { create(:page, work: work) }

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_transcribe_page_path(collection.owner, collection, page.work, next_page.id)
          )
        end
      end

      context 'when last non-blank page is set to blank' do
        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_transcribe_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when last blank page was set to blank again' do
        let!(:page) { create(:page, work: work, status: :blank, translation_status: :blank) }

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_transcribe_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when last non-blank page was set to not blank again' do
        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0'
            }
          }
        end

        it 'renders status' do
          login_as owner
          subject

          # This branch will go through the rest of the save_transcription logic
          # TODO: Add tests for said branch
          expect(response).to have_http_status(:no_content)
        end
      end

      context 'when last blank page was set to not blank' do
        let!(:page) { create(:page, work: work, status: :blank, translation_status: :blank) }

        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0'
            }
          }
        end

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_transcribe_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when needs_review == 1' do
        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0',
              needs_review: '1'
            }
          }
        end

        it 'renders status' do
          login_as owner
          subject

          # This branch will go through the rest of the needs_review logic
          # TODO: Add tests for said branch
          expect(response).to have_http_status(:no_content)
        end
      end
    end
  end

  # TODO: Full test suite for save_translation
  # For now, we cover the branch for mark_blank logic
  describe '#save_translation' do
    let(:action_path) { transcribe_save_translation_path }
    let(:params) { {} }

    let(:subject) { patch action_path, params: params }

    context 'mark_blank_logic' do
      let!(:search_attempt) do
        create(:search_attempt, user_id: owner.id, search_type: 'findaproject', query: page.title)
      end
      let(:params) do
        {
          page_id: page.id,
          page: {
            mark_blank: '1'
          }
        }
      end

      before do
        allow(Current).to receive(:session).and_return({ search_attempt_id: search_attempt.id })
      end

      context 'when non-blank page is set to blank' do
        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_display_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when blank page was set to blank again' do
        let!(:page) { create(:page, work: work, status: :blank, translation_status: :blank) }

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_display_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when non-blank page was set to not blank again' do
        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0'
            }
          }
        end

        it 'renders status' do
          login_as owner
          subject

          # This branch will go through the rest of the save_transcription logic
          # TODO: Add tests for said branch
          expect(response).to have_http_status(:no_content)
        end
      end

      context 'when blank page was set to not blank' do
        let!(:page) { create(:page, work: work, status: :blank, translation_status: :blank) }

        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0'
            }
          }
        end

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_display_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when needs_review == 1' do
        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0',
              needs_review: '1'
            }
          }
        end

        it 'renders status' do
          login_as owner
          subject

          # This branch will go through the rest of the needs_review logic
          # TODO: Add tests for said branch
          expect(response).to have_http_status(:no_content)
        end
      end
    end
  end
end
