# frozen_string_literal: true

require 'spec_helper'

describe 'transcription form submission', js: true do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner: owner) }
  let(:work_page) { create(:page, work: work, position: 1) }

  around do |example|
    previous_asset_host = Capybara.asset_host
    Capybara.asset_host = nil
    example.run
  ensure
    Capybara.asset_host = previous_asset_host
  end

  before do
    login_as(owner, scope: :user)
    visit collection_transcribe_page_path(owner, collection, work, work_page)
    expect(page).to have_selector('.CodeMirror')
    check('page_mark_blank')
    expect(page).to have_button('Preview', disabled: true)
    uncheck('page_mark_blank')
    page.execute_script(<<~JS)
      sessionStorage.setItem('transcriptionErrors', '[]');
      window.addEventListener('error', function(event) {
        var errors = JSON.parse(sessionStorage.getItem('transcriptionErrors'));
        errors.push(event.message);
        sessionStorage.setItem('transcriptionErrors', JSON.stringify(errors));
      });
    JS
  end

  after do
    collection.categories.destroy_all
    collection.destroy!
    owner.destroy!
  end

  def expect_no_submission_errors
    expect(page.evaluate_script("JSON.parse(sessionStorage.getItem('transcriptionErrors'))")).to eq([])
  end

  it 'saves the current CodeMirror text and records a version without a recursive submit' do
    text = "A deed between [[Test Person]] and [[Other Person]].\nThe next line."
    fill_in_editor_field(text)
    find('#save_button_top').click

    expect(page).to have_content('Saved')
    expect_no_submission_errors
    expect(work_page.reload.source_text).to eq(text.gsub("\n", "\r\n"))
    expect(work_page.page_versions.first.transcription).to eq(text.gsub("\n", "\r\n"))

    visit collection_transcribe_page_path(owner, collection, work, work_page)
    expect(page.evaluate_script('myCodeMirror.getValue()')).to eq(text)
  end

  it 'previews and returns to editing without a recursive submit' do
    fill_in_editor_field('Text for the preview')
    click_button('Preview')

    expect(page).to have_selector('.page-preview', text: 'Text for the preview')
    expect_no_submission_errors
    click_button('Edit')

    expect(page).to have_selector('.CodeMirror')
    expect(page.evaluate_script('myCodeMirror.getValue()')).to eq('Text for the preview')
    expect_no_submission_errors
  end

  it 'allows cancelling and then confirming that a page with text should be blank' do
    fill_in_editor_field('Text that will be discarded')
    check('page_mark_blank')
    find('#save_button_top').click

    expect(page).to have_selector('#custom-alert', visible: true)
    expect(work_page.reload).not_to be_status_blank
    click_button('Cancel')
    expect(page).to have_selector('#custom-alert', visible: false)
    expect(page.evaluate_script('myCodeMirror.getValue()')).to eq('Text that will be discarded')

    find('#save_button_top').click
    click_button('Blank out this page')

    expect(page).to have_content('Saved')
    expect(work_page.reload).to be_status_blank
    expect_no_submission_errors
  end

  it 'marks an empty page blank without a confirmation or recursive submit' do
    check('page_mark_blank')
    find('#save_button_top').click

    expect(page).to have_content('Saved')
    expect(work_page.reload).to be_status_blank
    expect_no_submission_errors
  end
end
