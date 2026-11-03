require 'spec_helper'

RSpec.describe 'Anonymous access and malformed URL handling', type: :request do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:visitor) { create(:unique_user) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, user_download: true) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  before do
    Current.user = owner
    stub_const('SMTP_ENABLED', false)
  end

  after { Warden.test_reset! }

  describe 'work downloads and direct functionality' do
    it 'keeps reading public but hides the Download tab without a session' do
      get collection_read_work_path(owner, collection, work)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.css('#work-tabs a').map { |a| a['href'] }).not_to include(download_collection_work_path(owner, collection, work))
    end

    it 'denies the direct Download URL without a session' do
      get download_collection_work_path(owner, collection, work)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'allows a registered user when user downloads are enabled' do
      login_as visitor
      get download_collection_work_path(owner, collection, work)
      expect(response).to have_http_status(:ok)
    end

    it 'denies non-owners when user downloads are disabled' do
      collection.update!(user_download: false)
      login_as visitor
      get download_collection_work_path(owner, collection, work)
      expect(response).to have_http_status(:forbidden)
    end

    it 'allows the owner when user downloads are disabled' do
      collection.update!(user_download: false)
      login_as owner
      get download_collection_work_path(owner, collection, work)
      expect(response).to have_http_status(:ok)
    end

    it 'supports an established guest session when user downloads are enabled' do
      stub_const('GUEST_TRANSCRIPTION_ENABLED', true)
      allow_any_instance_of(ApplicationController).to receive(:check_recaptcha).and_return(true)
      post application_guest_transcription_path(page_id: page.id)
      get download_collection_work_path(owner, collection, work)
      expect(response).to have_http_status(:ok)
    end

    it 'does not start PDF generation for an anonymous direct request' do
      expect(Work::Export::Printable).not_to receive(:new)
      post export_printable_path(collection, work), params: { format: 'pdf', edition: 'text' }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'guards the accessible-PDF dialog and owner printout configuration' do
      get export_new_grover_export_path(collection, work)
      expect(response).to redirect_to(new_user_session_path)
      get configurable_printout_collection_work_path(owner, collection, work)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'preserves owner printout configuration and rejects ordinary users' do
      login_as visitor
      get configurable_printout_collection_work_path(owner, collection, work)
      expect(response).to have_http_status(:forbidden)
      login_as owner
      get configurable_printout_collection_work_path(owner, collection, work)
      expect(response).to have_http_status(:ok)
    end

    it 'guards plaintext and legacy TEI exports' do
      get export_work_plaintext_verbatim_path(work_id: work.id)
      expect(response).to redirect_to(new_user_session_path)
      get export_tei_path(work.slug)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'does not queue a work bulk export for anonymous or ordinary users' do
      arguments = { work_id: work.id, bulk_export: { collection_id: collection.slug, plaintext_verbatim_page: true } }
      expect do
        post bulk_export_create_for_work_path(collection), params: arguments
      end.not_to change(BulkExport, :count)
      expect(response).to have_http_status(:redirect)
      login_as visitor
      expect do
        post bulk_export_create_for_work_path(collection), params: arguments
      end.not_to change(BulkExport, :count)
      expect(response).to have_http_status(:redirect)
    end

    it 'keeps public IIIF manifests accessible but guards generated export URLs' do
      get iiif_manifest_path(work.id)
      expect(response).to have_http_status(:ok)
      get iiif_work_export_plaintext_emended_path(work.id)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows explicit public API exports for server-to-server integrations' do
      collection.update!(api_access: true)
      get iiif_work_export_plaintext_emended_path(work.id)
      expect(response).to have_http_status(:ok)
    end

    it 'allows an owner API token and rejects an unrelated token when downloads are disabled' do
      collection.update!(user_download: false)
      owner.update!(api_key: User.generate_api_key)
      visitor.update!(api_key: User.generate_api_key)
      get iiif_work_export_plaintext_verbatim_path(work.id), headers: { Authorization: "Token token=#{visitor.api_key}" }
      expect(response).to have_http_status(:forbidden)
      get iiif_work_export_plaintext_verbatim_path(work.id), headers: { Authorization: "Token token=#{owner.api_key}" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'editor heartbeats' do
    it 'uses the collection owner context and records activity for a signed-in transcriber' do
      login_as visitor
      heartbeat = collection_transcribe_still_editing_path(owner.slug, collection.slug, work.slug, page.id)
      get collection_transcribe_page_path(owner, collection, work, page)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(heartbeat)

      get heartbeat
      expect(response).to have_http_status(:ok)
      expect(page.reload.edit_started_by_user_id).to eq(visitor.id)
      expect(page.edit_started_at).to be_present
    end

    it 'returns session expired without updating the page when signed out' do
      get collection_transcribe_still_editing_path(owner.slug, collection.id, work.id, page.id)
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to eq('session expired')
      expect(page.reload.edit_started_at).to be_nil
    end

    it 'rejects mismatched collection, work, and owner contexts without recording activity' do
      login_as visitor
      other = create(:collection, owner_user_id: owner.id)
      other_work = create(:work, collection: collection, owner_user_id: owner.id)
      [[owner.slug, other.id, work.id], [owner.slug, collection.id, other_work.id],
       [visitor.slug, collection.id, work.id]].each do |slug, collection_id, work_id|
        get collection_transcribe_still_editing_path(slug, collection_id, work_id, page.id)
        expect(response).to have_http_status(:not_found)
        expect(page.reload.edit_started_at).to be_nil
      end
    end

    it 'preserves public document-set context when its parent collection is private' do
      collection.update!(visibility: :private)
      set = create(:document_set, :public, collection: collection, owner_user_id: owner.id, works: [work])
      login_as visitor
      heartbeat = collection_transcribe_still_editing_path(owner.slug, set.slug, work.slug, page.id)
      active = active_editing_collection_work_path(owner.slug, set.slug, work.slug, page.id)
      get collection_transcribe_page_path(owner, set, work, page)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(heartbeat, active)
      get active
      expect(response).to have_http_status(:ok)
      get heartbeat
      expect(response).to have_http_status(:ok)
      expect(page.reload.edit_started_by_user_id).to eq(visitor.id)
    end
  end

  describe 'personal dashboards' do
    it 'preserves the explicitly public all-deeds feed' do
      get dashboard_deeds_path, params: { all: true }
      expect(response).to have_http_status(:ok)
    end
    [:dashboard_watchlist_path, :dashboard_exports_path, :dashboard_deeds_path].each do |route|
      it "requires a session for #{route}" do
        get public_send(route)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'invalid context and records' do
    it 'does not fall back to global notes for an unknown collection' do
      get collection_notes_path(collection_id: 'missing-collection-5996')
      expect(response).to have_http_status(:not_found)
      expect(response.headers['Location']).to be_nil
    end

    it 'rejects a nonexistent or mismatched collection on a valid work URL' do
      other = create(:collection, owner_user_id: owner.id)
      [other.slug, 'missing-collection-5996'].each do |slug|
        get "/#{owner.slug}/#{slug}/#{work.slug}"
        expect(response).to have_http_status(:not_found)
      end
    end

    it 'rejects a work outside the requested document set' do
      set = create(:document_set, :public, collection_id: collection.id, owner_user_id: owner.id)
      get collection_read_work_path(owner, set, work)
      expect(response).to have_http_status(:not_found)
    end

    it 'rejects an incorrect owner prefix on a public work' do
      get collection_read_work_path(visitor, collection, work)
      expect(response).to have_http_status(:not_found)
    end

    it 'rejects a page requested under a different work' do
      other_work = create(:work, collection: collection, owner_user_id: owner.id)
      get collection_display_page_path(owner, collection, other_work, page)
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an unknown works-list collection' do
      get collection_works_list_path(owner, 'missing-collection-5996')
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 instead of constructing a namespaced redirect for telemetry' do
      login_as visitor
      post transcribe_suspicious_behaviors_path(collection_id: 999_999_999, page_id: page.id), as: :json,
        params: { suspicious_behavior: { behavior_type: 'large_paste', metadata: { content: 'test' } } }
      expect(response).to have_http_status(:not_found)
      expect(response.headers['Location']).to be_nil
    end

    it 'handles a missing telemetry page through the RecordNotFound handler' do
      login_as visitor
      post transcribe_suspicious_behaviors_path(collection_id: collection.id, page_id: 999_999_999), as: :json,
        params: { suspicious_behavior: { behavior_type: 'large_paste', metadata: { content: 'test' } } }
      expect(response).to have_http_status(:not_found)
      expect(response.headers['Location']).to be_nil
    end

    it 'returns a client error for malformed JSON pagination' do
      get collection_read_work_path(owner, collection, work), params: { page: '(select 1)' }, headers: { Accept: 'application/json' }
      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects a telemetry page belonging to another collection without creating records' do
      other = create(:collection, owner_user_id: owner.id)
      login_as visitor
      expect do
        post transcribe_suspicious_behaviors_path(collection_id: other.id, page_id: page.id), as: :json,
          params: { suspicious_behavior: { behavior_type: 'large_paste', metadata: { content: 'test' } } }
      end.not_to change(SuspiciousBehavior, :count)
      expect(response).to have_http_status(:not_found)
    end

    it 'denies telemetry writes for a user who cannot transcribe a read-only collection' do
      collection.update!(visibility: :read_only)
      login_as visitor
      expect do
        post transcribe_suspicious_behaviors_path(collection_id: collection.id, page_id: page.id), as: :json,
          params: { suspicious_behavior: { behavior_type: 'large_paste', metadata: { content: 'test' } } }
      end.not_to change(SuspiciousBehavior, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 404 for guest transcription without a page' do
      get transcribe_guest_path
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an owner profile with no usable slug' do
      owner.update_column(:slug, nil)
      get "/#{owner.id}"
      expect(response).to have_http_status(:not_found)
    end

    it 'rejects unknown collection and category IDs for article lists' do
      get article_list_path(collection_id: 'missing-collection-5996')
      expect(response).to have_http_status(:not_found)
      get collection_subjects_path(owner, collection), params: { selected_category_id: 999_999_999 }
      expect(response).to have_http_status(:not_found)
      other = create(:collection, owner_user_id: owner.id)
      get collection_subjects_path(owner, collection), params: { selected_category_id: other.categories.first.id }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 406 for a JSON landing-page request' do
      get '/', headers: { Accept: 'application/json' }
      expect(response).to have_http_status(:not_acceptable)
    end

    it 'returns 406 for JSON article history and still renders valid HTML history' do
      article = create(:article, collection: collection, pages: [page])
      path = collection_article_version_path(owner, collection, article)
      get path, headers: { Accept: 'application/json' }
      expect(response).to have_http_status(:not_acceptable)
      get path
      expect(response).to have_http_status(:ok)
    end

    it 'can render an old read-work URL with Elasticsearch search enabled' do
      stub_const('ELASTIC_ENABLED', true)
      get display_read_work_path(work_id: work.id, page: 1)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(collection_work_search_path(owner, collection, work))
    end

    it 'rejects stale and disabled forum contexts' do
      get "/#{owner.slug}/missing-collection-5996/forum/help"
      expect(response).to have_http_status(:not_found)
      get "/#{owner.slug}/#{collection.slug}/forum/help"
      expect(response).to have_http_status(:not_found)
    end

    it 'matches forum-link visibility and preserves access for signed-in readers' do
      collection.enable_messageboards
      board = collection.messageboard_group.messageboards.find_by!(name: 'Help')
      path = "http://www.example.com/#{owner.slug}/#{collection.slug}/forum/#{board.to_param}"
      get path
      expect(URI.parse(response.location).path).to eq('/users/sign_in')
      login_as visitor
      get path
      expect(response).to have_http_status(:ok)
      get "http://www.example.com/#{owner.slug}/#{collection.slug}/forum/messageboard-groups/#{collection.messageboard_group.id}"
      expect(response).to have_http_status(:ok)
    end

    it 'rejects a messageboard or group requested under another collection' do
      collection.enable_messageboards
      other = create(:collection, owner_user_id: owner.id)
      other.enable_messageboards
      board = other.messageboard_group.messageboards.find_by!(name: 'Help')
      login_as visitor
      get "http://www.example.com/#{owner.slug}/#{collection.slug}/forum/#{board.to_param}"
      expect(response).to have_http_status(:not_found)
      get "http://www.example.com/#{owner.slug}/#{collection.slug}/forum/messageboard-groups/#{other.messageboard_group.id}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'notes and orphan associations' do
    let!(:note) { create(:note, collection: collection, work: work, page: page, user: owner) }

    it 'renders a deleted author without anonymous editing controls' do
      note.update_columns(user_id: nil)
      get collection_display_page_path(owner, collection, work, page)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Deleted user')
      expect(response.parsed_body.css("#note-#{note.id} .user-bubble_actions")).to be_empty
      get collection_page_discussions_path(owner, collection)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Deleted user')
    end

    it 'links pageless notes to the work and tolerates notes without a work' do
      note.update_columns(page_id: nil)
      get collection_notes_path(collection_id: collection.slug)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(collection_read_work_path(owner, collection, work))
      note.update_columns(work_id: nil)
      get collection_notes_path(collection_id: collection.slug)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(note.title)
    end

    it 'does not include private collection notes in the global public listing' do
      secret = create(:collection, owner_user_id: owner.id, visibility: :private)
      hidden = create(:note, collection: secret, work: work, page: page, user: owner, title: 'Private note 5996')
      get notes_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(note.title)
      expect(response.body).not_to include(hidden.title)
    end

    it 'denies work access when its collection association is missing' do
      create(:deed, user: visitor, collection: collection, work: work, page: page, deed_type: DeedType::PAGE_EDIT)
      work.update_column(:collection_id, nil)
      expect(work.reload.access_object(nil)).to be_nil
      expect(work.access_object(owner)).to be_nil
      get display_read_work_path(work_id: work.id)
      expect(response).to have_http_status(:not_found)
      get user_profile_path(visitor)
      expect(response).to have_http_status(:ok)
    end
  end
end
