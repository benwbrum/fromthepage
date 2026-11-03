require 'spec_helper'

RSpec.describe 'Restoring transcription drafts after a session change', type: :request do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id, supports_translation: true) }
  let!(:page) { create(:page, work: work, source_text: 'Saved version') }
  let(:editor_path) { collection_transcribe_page_path(owner, collection, work, page) }
  let(:save_path) { collection_oneoff_review_page_save_path(owner, collection, page) }
  let(:text) { "My unsaved draft <script>alert('draft-content')</script> & more" }
  let(:draft_params) do
    { page_id: page.id, page: { mark_blank: '0', source_text: text }, save_to_incomplete: '',
      authenticity_token: @original_form[:csrf], save_recovery_token: @original_form[:recovery] }
  end

  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
    Warden.test_reset!
  end

  before do
    Current.user = owner
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  def form
    node = response.parsed_body.at_css('form.page-editor')
    { csrf: node.at_css('input[name="authenticity_token"]')['value'],
      recovery: node.at_css('input[name="save_recovery_token"]')['value'], action: node['action'],
      id: node.at_css('input[name="recovery_id"]')&.[]('value') }
  end

  def open_original_form(user = owner, path = editor_path)
    login_as user
    get path
    expect(response).to have_http_status(:ok)
    @original_form = form
  end

  def new_session(user = owner)
    reset!
    login_as user
    get new_user_session_path
  end

  def recovery_id(url = response.location)
    Rack::Utils.parse_nested_query(URI(url).query)['recovery_id']
  end

  def expect_no_save
    saved = page.reload.attributes
    versions = PageVersion.count
    deeds = Deed.count
    yield
    expect(page.reload.attributes).to eq(saved)
    expect(PageVersion.count).to eq(versions)
    expect(Deed.count).to eq(deeds)
  end

  it 'returns a same-account re-login to the editor and saves only after a fresh explicit submission' do
    open_original_form
    new_session
    id = nil
    expect_no_save do
      patch save_path, params: draft_params
      expect(response).to have_http_status(:see_other)
      expect(response.headers['Cache-Control']).to include('no-store')
      expect(response.headers['Referrer-Policy']).to eq('same-origin')
      id = recovery_id
      expect(response.location).not_to include('source_text', 'draft-content')
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.at_css('#page_source_text').text.delete_prefix("\n")).to eq(text)
      expect(response.body).to include(I18n.t('transcribe.save_session_recovery.restored'))
      expect(response.parsed_body.at_css('header.header')).to be_present
      expect(response.parsed_body.css('section.signon')).to be_empty
      expect(response.parsed_body.css('script').any? { |script| script.text.include?("alert('draft-content')") }).to be(false)
    end
    fresh = form
    patch fresh[:action], params: draft_params.merge(authenticity_token: fresh[:csrf],
      save_recovery_token: fresh[:recovery], recovery_id: fresh[:id])
    expect(response).to have_http_status(:redirect)
    expect(page.reload.source_text).to eq(text)
    expect(Transcribe::Lib::DraftRecovery.fetch(id)).to be_nil
    follow_redirect! while response.redirect?
    expect(response.body).not_to include(I18n.t('transcribe.save_session_recovery.restored'))
    expect(response.body).not_to include(I18n.t('transcribe.save_session_recovery.unavailable'))
  end

  it 'styles logged-out recovery in the application layout and resumes after login in the other tab' do
    open_original_form
    reset!
    resume = nil
    expect_no_save do
      patch save_path, params: draft_params
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.at_css('header.header')).to be_present
      expect(response.body).to include('/assets/application')
      expect(response.parsed_body.at_css('section.signon a[target="_blank"][href="/users/sign_in"]')).to be_present
      resume = response.parsed_body.at_css('section.signon a.button.outline')['href']
      expect(recovery_id(resume)).to be_present
      expect(response.parsed_body.at_css('#submitted_text').text.delete_prefix("\n")).to eq(text)
    end
    login_as owner
    expect_no_save do
      get resume
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.at_css('#page_source_text').text.delete_prefix("\n")).to eq(text)
      expect(response.body).to include(I18n.t('transcribe.save_session_recovery.restored'))
    end
  end

  it 'does not automatically restore an unsigned or tampered form' do
    open_original_form
    new_session
    [nil, 'tampered'].each do |token|
      expect_no_save do
        patch save_path, params: draft_params.merge(save_recovery_token: token)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:save_session_recovery)
        expect(response.parsed_body.at_css('section.signon a[href="/users/sign_in"]')).to be_nil
      end
    end
  end

  it 'does not move a draft into a different account' do
    open_original_form
    visitor = create(:unique_user)
    new_session(visitor)
    expect_no_save do
      patch save_path, params: draft_params
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:save_session_recovery)
      expect(response.parsed_body.at_css('section.signon a[href="/users/sign_in"]')).to be_nil
    end
  end

  it 'binds cached drafts to both their account and page' do
    open_original_form
    new_session
    patch save_path, params: draft_params
    resume = response.location
    id = recovery_id
    visitor = create(:unique_user)
    new_session(visitor)
    get resume
    expect(response).to have_http_status(:forbidden)
    expect(response.body).not_to include('draft-content')
    new_session
    other_page = create(:page, work: work)
    get collection_transcribe_page_path(owner, collection, work, other_page, recovery_id: id)
    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include('draft-content')
  end

  it 'keeps a copyable draft when cache storage fails' do
    open_original_form
    new_session
    allow(Rails.cache).to receive(:write).and_return(false)
    expect_no_save do
      patch save_path, params: draft_params
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.at_css('#submitted_text').text.delete_prefix("\n")).to eq(text)
      expect(response.parsed_body.at_css('header.header')).to be_present
    end
  end

  it 'keeps a copyable draft when the shared cache is unavailable' do
    open_original_form
    new_session
    allow(Rails.cache).to receive(:write).and_raise(RuntimeError, 'Cache unavailable')
    expect_no_save do
      patch save_path, params: draft_params
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.at_css('#submitted_text').text.delete_prefix("\n")).to eq(text)
    end
  end

  it 'warns explicitly if a temporary draft is no longer available' do
    open_original_form
    new_session
    patch save_path, params: draft_params
    id = recovery_id
    Transcribe::Lib::DraftRecovery.delete(id)
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t('transcribe.save_session_recovery.unavailable'))
    expect(response.parsed_body.at_css('#page_source_text').text.delete_prefix("\n")).to eq('Saved version')
  end

  it 'does not restore automatically after editing permission is revoked' do
    collection.update!(visibility: :private, footer_block: 'Private collection footer 5995')
    visitor = create(:unique_user)
    collection.collaborators << visitor
    open_original_form(visitor)
    new_session(visitor)
    collection.collaborators.delete(visitor)
    expect_no_save do
      patch save_path, params: draft_params
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:save_session_recovery)
      expect(response.parsed_body.at_css('#submitted_text').text.delete_prefix("\n")).to eq(text)
      expect(response.body).not_to include('Private collection footer 5995')
    end
  end

  it 'preserves public document-set context when the parent collection is private' do
    collection.update!(visibility: :private, supports_document_sets: true)
    set = create(:document_set, :public, collection: collection, owner_user_id: owner.id, works: [work])
    visitor = create(:unique_user)
    path = collection_transcribe_page_path(owner, set, work, page)
    open_original_form(visitor, path)
    new_session(visitor)
    expect_no_save do
      patch collection_oneoff_review_page_save_path(owner, set, page), params: draft_params
      expect(response).to have_http_status(:see_other)
      expect(response.location).to include(set.slug)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.at_css('#page_source_text').text.delete_prefix("\n")).to eq(text)
    end
  end

  it 'preserves long drafts outside the session cookie and filters recovery credentials' do
    open_original_form
    new_session
    long_text = 'Long unsaved draft. ' * 2_000
    patch save_path, params: draft_params.deep_merge(page: { source_text: long_text })
    expect(response).to have_http_status(:see_other)
    expect(response.location.length).to be < 1_000
    expect(response.headers['Set-Cookie'].to_s.length).to be < 4_096
    follow_redirect!
    expect(response.parsed_body.at_css('#page_source_text').text.delete_prefix("\n")).to eq(long_text)
    filtered = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
                                           .filter(save_recovery_token: 'secret', recovery_id: 'secret')
    expect(filtered.values).to eq(['[FILTERED]', '[FILTERED]'])
  end

  it 'restores a translation and gives it a fresh, usable save form' do
    path = collection_translate_page_path(owner, collection, work, page)
    open_original_form(owner, path)
    new_session
    expect_no_save do
      patch transcribe_save_translation_path, params: draft_params.merge(page: { source_translation: text }, save: 'Save')
      expect(response).to have_http_status(:see_other)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.at_css('#page_source_translation').text.delete_prefix("\n")).to eq(text)
    end
    fresh = form
    patch fresh[:action], params: { page_id: page.id, page: { source_translation: text }, save: 'Save',
                                   authenticity_token: fresh[:csrf], save_recovery_token: fresh[:recovery], recovery_id: fresh[:id] }
    expect(response).to have_http_status(:redirect)
    expect(page.reload.source_translation).to eq(text)
    expect(Transcribe::Lib::DraftRecovery.fetch(fresh[:id])).to be_nil
  end

  context 'with field-based transcription' do
    let!(:collection) { create(:collection, owner_user_id: owner.id, field_based: true) }
    let!(:field) { create(:transcription_field, :as_transcription, :text_field, collection: collection, label: 'Recovered text') }
    let!(:sheet) { create(:transcription_field, :as_transcription, :spreadsheet_field, collection: collection, label: 'Rows') }
    let!(:column) { create(:spreadsheet_column, transcription_field: sheet, label: 'Column', position: 0) }
    let(:fields) { { field.id.to_s => { 'recovered-text' => 'Recovered field value' }, sheet.id.to_s => { 'rows' => [['Cell draft']].to_json } } }

    it 'populates the real text and spreadsheet editors without saving their JSON' do
      open_original_form
      new_session
      expect_no_save do
        patch save_path, params: draft_params.merge(fields: fields)
        expect(response).to have_http_status(:see_other)
        follow_redirect!
        expect(response).to have_http_status(:ok)
        input = response.parsed_body.at_css("input[name='fields[#{field.id}][recovered-text]']")
        expect(input['value']).to eq('Recovered field value')
        expect(response.body).to include('Cell draft')
      end
    end

    it 'retains copyable JSON if the field configuration has changed' do
      open_original_form
      new_session
      patch save_path, params: draft_params.merge(fields: fields.merge('999999999' => { 'unknown' => 'Still recoverable' }))
      expect(response).to have_http_status(:see_other)
      follow_redirect!
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:save_session_recovery)
      expect(response.parsed_body.at_css('#submitted_fields').text).to include('Still recoverable')
      expect(response.parsed_body.at_css('header.header')).to be_present
    end
  end
end
