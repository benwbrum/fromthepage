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
    visit dashboard_owner_path
    page.find('.collection_title', text: @collection.title).click_link(@collection.title)
    page.find('.tabs').click_link("Export")
    expect(page).to have_content("Export All Works")
    expect(page).to have_content(@work.title)
    page.find('#btnExportAll').click
    expect(page.response_headers['Content-Type']).to eq 'application/zip'
  end

  it "exports the subject index" do
    visit "/export?collection_id=#{@collection.id}"
    expect(page).to have_content("Export Subject Index")
    expect(page).to have_content(@work.title)
    page.find('#btnCsvExport').click
    expect(page.response_headers['Content-Type']).to eq 'application/csv'
  end

  it "exports a work as xhtml" do
    visit "/export?collection_id=#{@collection.id}"
    expect(page).to have_content("Export Individual Works")
    page.find('tr', text: @work.title).click_link("XHTML")
    expect(page.current_path).to eq ("/export/show")
    expect(page).to have_content(@work.title)
    expect(page).to have_content("Page Transcripts")
    expect(page).to have_content(@page.title)
  end

  it "exports a work as tei" do
    visit "/export?collection_id=#{@collection.id}"
    expect(page).to have_content("Export Individual Works")
    page.find('tr', text: @work.title).click_link("TEI")
    expect(page.current_path).to eq ("/export/tei")
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