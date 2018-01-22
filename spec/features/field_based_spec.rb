
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
    page.find('#new-fields tr[3]').fill_in('transcription_fields__label', with: 'Second field')
    page.find('#new-fields tr[3]').select('textarea', from: 'transcription_fields__input_type')
    page.find('#new-fields tr[4]').fill_in('transcription_fields__label', with: 'Third field')
    click_button 'Save'
    expect(TranscriptionField.all.count).to eq 3
  end

  #note - would like to do select field, but trouble with the js

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

  #note: these are hidden unless there is table data
  it "exports a table csv" do
    work = @collection.works.first
    visit "/export?collection_id=#{@collection.id}"
    expect(page).to have_content("Export Individual Works")
    page.find('tr', text: work.title).find('.btnCsvTblExport').click
    expect(page.response_headers['Content-Type']).to eq 'application/csv'
  end

  it "sets collection back to document based transcription" do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.click_link("Revert to Document Based Transcription")
    expect(page).not_to have_selector('a', text: 'Edit Fields')
  end

end
