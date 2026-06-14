# frozen_string_literal: true

require 'spec_helper'

describe 'export tasks' do
  let(:owner) { create(:unique_user, :owner) }
  let(:admin) { create(:unique_user, :admin) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner: owner) }
  let(:work_page) do
    create(
      :page,
      :transcribed,
      work: work,
      source_text: 'Isolated export transcript'
    )
  end

  before do
    DatabaseCleaner.start
    work_page
    login_as(owner, scope: :user)
  end

  after do
    DatabaseCleaner.clean
  end

  it 'queues an export of all works in a collection' do
    allow_any_instance_of(BulkExport).to receive(:submit_export_process)
    visit collection_export_path(owner, collection)

    expect(page).to have_content('Export All Works')
    expect(page).to have_content(work.title)
    page.find('#btnExportAll').click
    expect(page.response_headers['Content-Type']).to eq('text/html; charset=utf-8')

    export_formats.each { |format| page.check("bulk_export_#{format}") }
    click_button('Start Export')

    expect(page).to have_content('Queued')
    bulk_export = collection.bulk_exports.find_by!(user: owner)
    expect(bulk_export).to have_attributes(status: 'queued', html_page: true, tei_work: true, static: true)

    login_as(admin, scope: :user)
    visit bulk_export_index_path

    expect(page).to have_content('Administration')
    expect(page).to have_content(collection.title)
  end

  it 'exports a work as XHTML' do
    visit collection_export_path(owner, collection)

    expect(page).to have_content('Export Individual Works')
    page.find('tr', text: work.title).click_link('HTML')

    expect(page.current_path).to eq(export_show_path)
    expect(page).to have_content(work.title)
    expect(page).to have_content('Page Transcripts')
    expect(page).to have_content(work_page.title)
  end

  it 'exports a work as plain text' do
    expect(work.reload.verbatim_transcription_plaintext).to include('Isolated export transcript')
    visit collection_export_path(owner, collection)

    expect(page).to have_content('Export Individual Works')
    page.find('tr', text: work.title).click_link('Plain text')

    expect(page.current_path).to eq(export_work_plaintext_verbatim_path)
    expect(page.body).to include('Isolated export transcript')
  end

  it 'exports a work as TEI' do
    visit collection_export_path(owner, collection)

    expect(page).to have_content('Export Individual Works')
    page.find('tr', text: work.title).click_link('TEI')

    expect(page.current_path).to eq(export_tei_path(work.slug))
    expect(page).to have_content(work.title)
    expect(page).to have_content('TEI export')
  end

  it 'does not offer table CSV exports without table data' do
    visit collection_export_path(owner, collection)

    expect(page).to have_content('Export Individual Works')
    expect(page.find('tr', text: work.title)).not_to have_selector('.btnCsvTblExport')
    expect(page).not_to have_content('Export All Tables')
    expect(page).not_to have_selector('#btnExportTables')
  end

  def export_formats
    %w[
      html_page
      html_work
      plaintext_verbatim_page
      plaintext_verbatim_work
      plaintext_emended_work
      plaintext_emended_page
      plaintext_searchable_work
      plaintext_searchable_page
      tei_work
      table_csv_work
      table_csv_collection
      subject_csv_collection
      work_metadata_csv
      static
    ]
  end
end
