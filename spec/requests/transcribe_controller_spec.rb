require 'spec_helper'

describe TranscribeController do
  before do
    User.current_user = owner
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

    it 'sets social media meta tags for page with source_text' do
      page.update!(source_text: '<p>This is transcribed text content.</p>')
      
      expect_any_instance_of(ApplicationHelper).to receive(:set_social_media_meta_tags).with(
        title: /#{work.title} - /,
        description: kind_of(String),
        image_url: anything,
        url: anything,
        type: 'article'
      )

      login_as owner
      subject
    end

    it 'sets social media meta tags for page without source_text' do
      page.update!(source_text: nil)
      
      expect_any_instance_of(ApplicationHelper).to receive(:set_social_media_meta_tags).with(
        title: /#{work.title} - /,
        description: /A page from .* in the .* project/,
        image_url: anything,
        url: anything,
        type: 'article'
      )

      login_as owner
      subject
    end
  end
end
