
require 'spec_helper'

describe "collection settings js tasks", :order => :defined do
  Capybara.javascript_driver = :webkit

  before :all do
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.second
  end

  before :each do
    login_as(@owner, :scope => :user)
  end    

  it "sets collection to field based transcription" do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.click_link("Enable Field Based Transcription")
    expect(page).to have_content("Edit Transcription Fields")
    page.find('.tabs').click_link("Settings")
    expect(page).to have_selector('a', text: 'Edit Fields')
    page.find('.sidecol').click_link('Edit Fields')
    expect(page).to have_content("Edit Transcription Fields")
  end

  it "edits fields for transcription" do
    expect(TranscriptionField.all.count).to eq 0
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Edit Fields")
    page.find('#new-fields tr[2]').fill_in('transcription_fields__label', with: 'First field')
    page.find('#new-fields tr[2]').fill_in('transcription_fields__percentage', with: 20)
    page.find('#new-fields tr[3]').fill_in('transcription_fields__label', with: 'Second field')
    page.find('#new-fields tr[3]').select('textarea', from: 'transcription_fields__input_type')
    page.find('#new-fields tr[4]').fill_in('transcription_fields__label', with: 'Third field')
    page.find('#new-fields tr[3]').select('select', from: 'transcription_fields__input_type')
    click_button 'Save'
    expect(page).to have_content("Select fields must have an options list.")
    expect(TranscriptionField.last.input_type).to eq "text"
    expect(TranscriptionField.all.count).to eq 3
    expect(TranscriptionField.first.percentage).to eq 20
  end

  it "checks the field preview on edit page" do
    #check the field preview
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Edit Fields")
    expect(page.find('div.editarea')).to have_content("First field")
    expect(page.find('div.editarea')).to have_content("Second field")
    expect(page.find('div.editarea')).to have_content("Third field")
    #check field width for first field (set to 20%)
    expect(page.find('div.editarea span[1]')[:style]).to eq "width:19%"
    #check field width for second field (not set)
    expect(page.find('div.editarea span[2]')[:style]).not_to eq "width:19%"
  end

  it "adds fields for transcription", :js => true do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Edit Fields")
    count = page.all('#new-fields tr').count
    click_button 'Add Additional Field'
    expect(page.all('#new-fields tr').count).to eq (count+1)
  end

  it "adds new line", :js => true do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Edit Fields")
    count = page.all('#new-fields tr').count
    line_count = page.all('#new-fields tr th#line_num').count
    click_button 'Add Additional Line'
    sleep(3)
    expect(page.all('#new-fields tr').count).to eq (count + 2)
    expect(page.all('#new-fields tr th#line_num').count).to eq (line_count + 1)
  end

  it "transcribes field-based works" do
    work = @collection.works.first
    field_page = work.pages.first
    visit collection_transcribe_page_path(@collection.owner, @collection, work, field_page)
    expect(page).not_to have_content("Autolink")
    expect(page).to have_content("First field")
    expect(page).to have_content("Second field")
    expect(page).to have_content("Third field")
    page.fill_in('fields_1_First_field', with: "Field one")
    page.fill_in('fields_2_Second_field', with: "Field two")
    page.fill_in('fields_3_Third_field', with: "Field three")
    click_button 'Save Changes'
    click_button 'Preview'
    expect(page.find('.page-preview')).to have_content("First field: Field one")
    click_button 'Edit'
    expect(page.find('.page-editarea')).to have_selector('#fields_1_First_field')
  end

  it "reorders a transcription field" do
    field1 = TranscriptionField.find_by(label: "First field").position
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Edit Fields")
    page.find('#new-fields tr[2]').click_link('Move down')
    expect(TranscriptionField.find_by(label: "First field").position).not_to eq field1
  end

  it "deletes a transcription field" do
    count = TranscriptionField.all.count
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Edit Fields")
    page.find('#new-fields tr[2]').click_link('Delete field')
    expect(TranscriptionField.all.count).to be < count
  end

  it "uses page arrows with unsaved transcription", :js => true do
    test_page = @collection.works.first.pages.second
    #next page arrow
    visit collection_transcribe_page_path(@collection.owner, @collection, test_page.work, test_page)
    page.fill_in('fields_1_First_field', with: "Field one")
    message = accept_alert do
      page.click_link("Next page")
    end
    sleep(3)
    expect(message).to have_content("You have unsaved changes.")
    visit collection_transcribe_page_path(@collection.owner, @collection, test_page.work, test_page)
    #previous page arrow - make sure it also works with notes
    fill_in('Write a new note...', with: "Test two")
    message = accept_alert do
      page.click_link("Previous page")
    end
    sleep(3)
    expect(message).to have_content("You have unsaved changes.")
  end

  #note: these are hidden unless there is table data
  it "exports a table csv" do
    work = @collection.works.first
    visit collection_export_path(@collection.owner, @collection)
    expect(page).to have_content("Export Individual Works")
    page.find('tr', text: work.title).find('.btnCsvTblExport').click
    expect(page.response_headers['Content-Type']).to eq 'application/csv'
  end

  it "exports table data for an entire collection" do
    visit collection_export_path(@collection.owner, @collection)
    expect(page).to have_content("Export All Tables")
    page.find('#btnExportTables').click
    expect(page.response_headers['Content-Type']).to eq 'application/csv'
  end

  it "sets collection back to document based transcription" do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.click_link("Revert to Document Based Transcription")
    expect(page).not_to have_selector('a', text: 'Edit Fields')
  end

end
