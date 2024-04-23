
require 'spec_helper'

describe "collection settings js tasks", :order => :defined do
  before :all do
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.second
  end

  before :each do
    login_as(@owner, :scope => :user)
  end

  it "sets collection to field based transcription", js: true do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link("Task Configuration")
    page.choose('Field-based transcription')
    page.click_link('Edit Fields')
    expect(page).to have_content("Edit Transcription Fields")
  end

  it "edits fields for transcription" do
    expect(TranscriptionField.all.count).to eq 0
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Fields")
    page.find('#new-fields tr[3]').fill_in('transcription_fields__label', with: 'First field')
    page.find('#new-fields tr[3]').fill_in('transcription_fields__percentage', with: 20)
    page.find('#new-fields tr[4]').fill_in('transcription_fields__label', with: 'Second field')
    page.find('#new-fields tr[4]').select('textarea', from: 'transcription_fields__input_type')
    page.find('#new-fields tr[5]').fill_in('transcription_fields__label', with: 'Third field')
    page.find('#new-fields tr[5]').select('select', from: 'transcription_fields__input_type')
    click_button 'Save'
    expect(page).to have_content("Select fields must have an options list.")
    expect(TranscriptionField.last.input_type).to eq "text"
    expect(TranscriptionField.all.count).to eq 3
    expect(TranscriptionField.first.percentage).to eq 20
  end

  it "checks the field preview on edit page" do
    #check the field preview
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Fields")
    expect(page.find('div.fields-preview')).to have_content("First field")
    expect(page.find('div.fields-preview')).to have_content("Second field")
    expect(page.find('div.fields-preview')).to have_content("Third field")
    #check field width for first field (set to 20%)
    expect(page.find('div.fields-preview .field-wrapper[1]')[:style]).to eq "width: 20%"
    #check field width for second field (not set)
    expect(page.find('div.fields-preview .field-wrapper[2]')[:style]).not_to eq "width: 20%"
    expect(TranscriptionField.count).to eq 3
  end

  it "adds fields for transcription", :js => true do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Fields")
    count = page.all('#new-fields tr').count
    click_button 'Add Additional Field'
    expect(page.all('#new-fields tr').count).to eq (count + 1)
    expect(TranscriptionField.count).to eq 3
  end

  it "adds new line", :js => true do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Fields")
    count = page.all('#new-fields tr').count
    line_count = page.all('#new-fields tr th.field-form_line').count
    click_button 'Add Additional Line'
    sleep(3)
    expect(page.all('#new-fields tr').count).to eq (count + 3)
    expect(page.all('#new-fields tr th.field-form_line').count).to eq (line_count + 1)
    expect(TranscriptionField.count).to eq 3
  end

  it "transcribes field-based works" do
    expect(TranscriptionField.count).to eq 3
    work = @collection.works.first
    field_page = work.pages.first
    expect(TranscriptionField.all.count).to eq 3
    visit collection_transcribe_page_path(@collection.owner, @collection, work, field_page)
    expect(TranscriptionField.all.count).to eq 3
    expect(page).not_to have_content("Autolink")
    expect(page).to have_content("First field")
    expect(page).to have_content("Second field")
    expect(page).to have_content("Third field")
    page.fill_in('fields_1_First_field', with: "Field one")
    page.fill_in('fields_2_Second_field', with: "Field < three")
    page.fill_in('fields_3_Third_field', with: "Field three")
    find('#save_button_top').click
    click_button 'Preview', match: :first
    expect(page.find('.page-preview')).to have_content("First field: Field one")
    click_button 'Edit', match: :first
    expect(page.find('.page-editarea')).to have_selector('#fields_1_First_field')
  end

  it "deletes a transcription field" do
    count = TranscriptionField.all.count
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Fields")
    page.find('#new-fields tr[5]').click_link('Delete field')
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
    fill_in('Write a new note or ask a question...', with: "Test two")
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
    content_type = page.response_headers['Content-Type']
    expect(page.response_headers['Content-Type']).to eq 'text/csv'
  end


  it "sets collection back to document based transcription", js: true do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.find('.side-tabs').click_link("Task Configuration")
    page.choose('Document-based transcription')
    expect(page.find_link('Edit Fields')).to match_css('[disabled]')
    expect(page.find_link('Configure Buttons')).to_not match_css('[disabled]')
  end

end
