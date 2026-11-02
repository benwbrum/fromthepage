require 'spec_helper'

RSpec.describe 'Transcription save session recovery', type: :request do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id, supports_translation: true) }
  let!(:page) { create(:page, work: work, source_text: 'Original text') }
  let(:editor_path) { collection_transcribe_page_path(owner, collection, work, page) }
  let(:save_path) { collection_oneoff_review_page_save_path(owner, collection, page) }
  let(:submitted_text) { "Unsaved text <script>alert('test')</script> & more" }
  let(:save_params) do
    { page_id: page.id, flow: '', quality_sampling_id: '', ai_draft_used: 'false',
      page: { mark_blank: '0', source_text: submitted_text }, save_to_incomplete: '' }
  end

  before { Current.user = owner }

  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
    Warden.test_reset!
  end

  def editor_token
    get editor_path
    expect(response).to have_http_status(:ok)
    response.parsed_body.at_css('#custom_form_id input[name="authenticity_token"]')['value']
  end

  def expect_rejected_save(status)
    original_attributes = page.reload.attributes
    original_versions = PageVersion.count
    original_deeds = Deed.count

    yield

    expect(response).to have_http_status(status)
    expect(response).to render_template(:save_session_recovery)
    expect(response.headers['Cache-Control']).to include('no-store')
    # Rails adds a leading newline that the browser strips from textarea values.
    expect(response.parsed_body.at_css('textarea').text.delete_prefix("\n")).to eq(submitted_text)
    expect(response.parsed_body.css('script')).to be_empty
    expect(response.parsed_body.at_css('a[href="/users/sign_in"]')).to be_present
    expect(page.reload.attributes).to eq(original_attributes)
    expect(PageVersion.count).to eq(original_versions)
    expect(Deed.count).to eq(original_deeds)
  end

  it 'rejects an invalid token before changing page state and preserves escaped text' do
    login_as owner
    editor_token
    expect_any_instance_of(TranscribeController).not_to receive(:load_objects_from_params)

    expect_rejected_save(:unprocessable_entity) do
      patch save_path, params: save_params.merge(authenticity_token: 'invalid')
    end
  end

  it 'rejects a missing token even when the user is signed in' do
    login_as owner
    editor_token

    expect_rejected_save(:unprocessable_entity) { patch save_path, params: save_params }
  end

  it 'recovers text when the form token survives but the session cookie is gone' do
    login_as owner
    stale_token = editor_token
    reset!

    expect_rejected_save(:unprocessable_entity) do
      patch save_path, params: save_params.merge(authenticity_token: stale_token)
    end
  end

  it 'rejects an old token after signing in with a new session' do
    login_as owner
    stale_token = editor_token
    reset!
    login_as owner
    editor_token

    expect_rejected_save(:unprocessable_entity) do
      patch save_path, params: save_params.merge(authenticity_token: stale_token)
    end
  end

  it 'recovers an anonymous save even with a valid anonymous session token' do
    get new_user_session_path
    token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']

    expect_rejected_save(:unauthorized) do
      patch save_path, params: save_params.merge(authenticity_token: token)
    end
  end

  it 'still saves with a valid signed-in session and token' do
    login_as owner
    token = editor_token

    patch save_path, params: save_params.merge(authenticity_token: token)

    expect(response).to have_http_status(:redirect)
    expect(page.reload.source_text).to eq(submitted_text)
    expect(page.page_versions.first.transcription).to eq(submitted_text)
    expect(page.deeds).not_to be_empty
  end

  it 'does not persist blank/review status changes for an unverified request' do
    login_as owner
    editor_token
    save_params[:page].merge!(mark_blank: '1', needs_review: '1')

    expect_rejected_save(:unprocessable_entity) { patch save_path, params: save_params }
  end

  it 'preserves field-based submissions as escaped, copyable JSON' do
    fields = { '123' => { 'Cell' => '</textarea><script>alert(1)</script>' } }
    login_as owner
    editor_token

    expect_rejected_save(:unprocessable_entity) do
      patch save_path, params: save_params.merge(fields: fields)
    end

    recovered = response.parsed_body.at_css('#submitted_fields').text.delete_prefix("\n")
    expect(JSON.parse(recovered)).to eq(fields)
  end

  it 'preserves a translation rejected by CSRF validation' do
    login_as owner
    editor_token
    translated_params = { page_id: page.id, page: { source_translation: submitted_text }, save: 'Save' }

    expect_rejected_save(:unprocessable_entity) do
      patch transcribe_save_translation_path, params: translated_params
    end

    expect(response.parsed_body.at_css("a[href='#{transcribe_translate_path(page_id: page.id)}']")).to be_present
  end

  it 'allows preview and return to editing with a valid token' do
    login_as owner
    token = editor_token
    safe_params = save_params.except(:save_to_incomplete).merge(authenticity_token: token)

    patch save_path, params: safe_params.merge(preview: 'Preview')
    expect(response).to have_http_status(:ok)
    expect(page.reload.source_text).to eq('Original text')

    patch save_path, params: safe_params.merge(edit: 'Edit')
    expect(response).to have_http_status(:ok)
    expect(page.reload.source_text).to eq('Original text')
  end

  context 'with a guest session' do
    before do
      stub_const('GUEST_TRANSCRIPTION_ENABLED', true)
      allow_any_instance_of(ApplicationController).to receive(:check_recaptcha).and_return(true)
      get new_user_session_path
      token = response.parsed_body.at_css('meta[name="csrf-token"]')['content']
      post application_guest_transcription_path(page_id: page.id), params: { authenticity_token: token }
      expect(response).to have_http_status(:redirect)
    end

    it 'still saves for a supported guest session' do
      token = editor_token
      patch save_path, params: save_params.merge(authenticity_token: token)

      expect(response).to have_http_status(:redirect)
      expect(page.reload.source_text).to eq(submitted_text)
      expect(page.deeds.first.user.guest?).to be(true)
    end

    it 'recovers text after the guest session cookie is lost' do
      token = editor_token
      reset!

      expect_rejected_save(:unprocessable_entity) do
        patch save_path, params: save_params.merge(authenticity_token: token)
      end
    end
  end

  it 'does not lose the original error if the user disappears before recovery' do
    login_as owner
    token = editor_token
    allow_any_instance_of(TranscribeController).to receive(:log_transcript_attempt) do |controller|
      allow(controller).to receive(:current_user).and_return(nil)
      raise StandardError, 'Original save failure'
    end

    expect_rejected_save(:unauthorized) do
      patch save_path, params: save_params.merge(authenticity_token: token)
    end
  end

  it 'can log an attempt without a user without printing submitted text' do
    controller = TranscribeController.new
    controller.instance_variable_set(:@collection, collection)
    controller.instance_variable_set(:@work, work)
    controller.instance_variable_set(:@page, page)
    allow(controller).to receive(:current_user).and_return(nil)
    allow(controller).to receive(:request).and_return(instance_double(ActionDispatch::Request, request_id: 'test'))
    logger = instance_double(ActiveSupport::BroadcastLogger)
    allow(controller).to receive(:logger).and_return(logger)
    expect(logger).to receive(:info).with("TRANSCRIPTION request_id=test user_id= page_id=#{page.id} attempt")

    expect { controller.send(:log_attempt, 'TRANSCRIPTION', submitted_text) }.not_to raise_error
  end

  it 'still saves translations with a valid session and token' do
    login_as owner
    get transcribe_translate_path(page_id: page.id)
    expect(response).to have_http_status(:ok)
    token = response.parsed_body.at_css('form.page-editor input[name="authenticity_token"]')['value']
    translated_params = { page_id: page.id, page: { mark_blank: '0', source_translation: 'New translation' },
                          save: 'Save', authenticity_token: token }

    patch transcribe_save_translation_path, params: translated_params

    expect(response).to have_http_status(:redirect)
    expect(page.reload.source_translation).to eq('New translation')
    expect(page.page_versions.first.source_translation).to eq('New translation')
  end

  it 'can recover an unverified malformed request without loading any records' do
    expect_any_instance_of(TranscribeController).not_to receive(:load_objects_from_params)

    patch transcribe_save_transcription_path, params: { authenticity_token: 'invalid' }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response).to render_template(:save_session_recovery)
    expect(response.parsed_body.at_css('#submitted_text').text.strip).to eq('')
    expect(response.parsed_body.css('a').length).to eq(1)
  end

  it 'filters tokens and submitted content from request parameter logs' do
    parameters = { authenticity_token: 'secret', page: { source_text: submitted_text, source_translation: 'private' },
                   fields: { '123' => { 'Cell' => 'private' } } }
    filtered = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(parameters)

    expect(filtered).to eq(authenticity_token: '[FILTERED]',
                           page: { source_text: '[FILTERED]', source_translation: '[FILTERED]' }, fields: '[FILTERED]')
  end
end
