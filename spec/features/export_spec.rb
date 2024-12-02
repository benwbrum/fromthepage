require 'spec_helper'

describe "export tasks" do

  before :all do
    @owner = User.find_by(login: OWNER)
    @collection = @owner.all_owner_collections.second
    @work = @collection.works.last
    @page = @work.pages.first
  end

  before :each do
    login_as(@owner, :scope => :user)
  end

  it "exports all works in a collection" do
    #TODO add better export tests for new UI
    visit dashboard_owner_path
    page.find('.collection_title', text: @collection.title).click_link(@collection.title)
    page.find('.tabs').click_link("Export")
    expect(page).to have_content("Export All Works")
    expect(page).to have_content(@work.title)
    page.find('#btnExportAll').click
    expect(page.response_headers['Content-Type']).to eq 'text/html; charset=utf-8'

    page.check('bulk_export_html_page')
    page.check('bulk_export_html_work')
    page.check('bulk_export_plaintext_verbatim_page')
    page.check('bulk_export_plaintext_verbatim_work')
    page.check('bulk_export_plaintext_emended_work')
    page.check('bulk_export_plaintext_emended_page')
    page.check('bulk_export_plaintext_searchable_work')
    page.check('bulk_export_plaintext_searchable_page')
    page.check('bulk_export_tei_work')
    page.check('bulk_export_table_csv_work')
    page.check('bulk_export_table_csv_collection')
    page.check('bulk_export_subject_csv_collection')
    page.check('bulk_export_work_metadata_csv')
    page.check('bulk_export_static')

    page.find('button', text: 'Start Export').click
    expect(page).to have_content("Queued")

    login_as(User.where(admin: true).first, :scope => :user)

    # wait for the background process to run
    1.upto(10) do
      sleep 5
      if BulkExport.last.status == 'finished'
        break
      end
    end

    visit bulk_export_index_path
    expect(page).to have_content("Administration")
  end


  it "exports a work as xhtml" do
    visit "/export?collection_id=#{@collection.id}"
    expect(page).to have_content("Export Individual Works")
    page.find('tr', text: @work.title).click_link("HTML")
    expect(page.current_path).to eq ("/export/show")
    expect(page).to have_content(@work.title)
    expect(page).to have_content("Page Transcripts")
    expect(page).to have_content(@page.title)
  end

  it "exports a work as plain text" do
    visit "/export?collection_id=#{@collection.id}"
    expect(page).to have_content("Export Individual Works")
    page.find('tr', text: @work.title).click_link("Plain text")
    expect(page.current_path).to eq ("/export/work_plaintext_verbatim")
    expect(page.all('pre', text: @work.title))
    expect(page.all('pre', text: @page.title))
  end

  it "exports a work as tei" do
    visit "/export?collection_id=#{@collection.id}"
    expect(page).to have_content("Export Individual Works")
    page.find('tr', text: @work.title).click_link("TEI")
    expect(page.current_path).to eq ("/export/#{@work.slug}/tei")
    expect(page).to have_content(@work.title)
    expect(page).to have_content("TEI export")
  end

  it "fails to export a table csv" do
    #this collection has no table data, so these shouldn't be available
    visit "/export?collection_id=#{@collection.id}"
    expect(page).to have_content("Export Individual Works")
    expect(page.find('tr', text: @work.title)).not_to have_selector('.btnCsvTblExport')
    expect(page).not_to have_content("Export All Tables")
    expect(page).not_to have_selector('#btnExportTables')

  end

end
