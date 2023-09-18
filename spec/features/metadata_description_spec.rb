
require 'spec_helper'

describe "Metadata Description" do
  before :all do
    @owner = User.find_by(login: OWNER)
    DatabaseCleaner.start
  end
  before :each do
    login_as(@owner, :scope => :user)
    visit '/feature/description/enable'
  end


  after :all do
    DatabaseCleaner.clean
  end

  let(:collection) { create(:collection, owner: @owner) }
  # factory code from work spec
  # let(:work_no_ocr){ create(:work, owner_user_id: @owner.id, collection: collection, ocr_correction: false) }
  # let(:page_no_ocr){ create(:page, work: work_no_ocr) }

  # let(:work_ocr)   { create(:work, owner_user_id: @owner.id, collection: collection, ocr_correction: true) }
  # let(:page_ocr)   { create(:page, work: work_ocr) }

  it "Enables and disables", js: true do
    visit edit_collection_path(@owner, collection)
    page.find('.side-tabs').click_link("Task Configuration")
    page.check("Enable metadata description")
    expect(page).to have_button('Edit Metadata Form', disabled: false)
    expect(Collection.last.data_entry_type).to eq(Collection::DataEntryType::TEXT_AND_METADATA)

    visit edit_collection_path(@owner, collection)
    page.find('.side-tabs').click_link("Task Configuration")
    page.uncheck("Enable metadata description")
    expect(page).to have_button('Edit Metadata Form', disabled: true)
    expect(Collection.last.data_entry_type).to eq(Collection::DataEntryType::TEXT_ONLY)
  end


  describe "Owner Flow" do
    before :each do
      login_as(@owner, :scope => :user)
      visit '/feature/description/enable'
    end

    it "edits description fields", js: true do
      visit edit_collection_path(@owner, collection)
      page.find('.side-tabs').click_link("Task Configuration")
      page.check("Enable metadata description")

      visit collection_path(@owner, collection)
      page.find('.tabs').click_link("Metadata Fields")
      page.find('#new-fields tr[3]').fill_in('transcription_fields__label', with: 'First field')
      page.find('#new-fields tr[3]').fill_in('transcription_fields__percentage', with: 20)
      page.find('#new-fields tr[4]').fill_in('transcription_fields__label', with: 'Second field')
      page.find('#new-fields tr[4]').select('textarea', from: 'transcription_fields__input_type')
      page.find('#new-fields tr[5]').fill_in('transcription_fields__label', with: 'Third field')
      page.find('#new-fields tr[5]').select('select', from: 'transcription_fields__input_type')
      old_field_count = TranscriptionField.all.count
      click_button 'Save'
      expect(page).to have_content("Select fields must have an options list.")
      expect(TranscriptionField.last.input_type).to eq "text"
      expect(TranscriptionField.last.field_type).to eq TranscriptionField::FieldType::METADATA
      expect(TranscriptionField.all.count).to eq old_field_count + 3
      expect(TranscriptionField.first.percentage).to eq 20


      # now check the field preview on the edit page
      visit collection_path(@owner, collection)
      page.find('.tabs').click_link("Metadata Fields")
      expect(page.find('div.fields-preview')).to have_content("First field")
      expect(page.find('div.fields-preview')).to have_content("Second field")
      expect(page.find('div.fields-preview')).to have_content("Third field")
      #check field width for first field (set to 20%)
      expect(page.find('div.fields-preview .field-wrapper[1]')[:style]).to eq "width: 20%"
      #check field width for second field (not set)
      expect(page.find('div.fields-preview .field-wrapper[2]')[:style]).not_to eq "width: 20%"

      # TODO separate and figure out the db cleaner business
    end

  end
end

# test code from field_based_spec
# describe "collection settings js tasks", :order => :defined do
#   before :all do
#     @owner = User.find_by(login: OWNER)
#     @collections = @owner.all_owner_collections
#     @collection = @collections.second
#   end

#   before :each do
#     login_as(@owner, :scope => :user)
#   end


#   it "checks the field preview on edit page" do
#     #check the field preview
#     visit collection_path(@collection.owner, @collection)
#     page.find('.tabs').click_link("Fields")
#     expect(page.find('div.fields-preview')).to have_content("First field")
#     expect(page.find('div.fields-preview')).to have_content("Second field")
#     expect(page.find('div.fields-preview')).to have_content("Third field")
#     #check field width for first field (set to 20%)
#     expect(page.find('div.fields-preview .field-wrapper[1]')[:style]).to eq "width: 20%"
#     #check field width for second field (not set)
#     expect(page.find('div.fields-preview .field-wrapper[2]')[:style]).not_to eq "width: 20%"
#     expect(TranscriptionField.count).to eq 3
#   end

#   it "adds fields for transcription", :js => true do
#     visit collection_path(@collection.owner, @collection)
#     page.find('.tabs').click_link("Fields")
#     count = page.all('#new-fields tr').count
#     click_button 'Add Additional Field'
#     expect(page.all('#new-fields tr').count).to eq (count + 1)
#     expect(TranscriptionField.count).to eq 3
#   end

#   it "adds new line", :js => true do
#     visit collection_path(@collection.owner, @collection)
#     page.find('.tabs').click_link("Fields")
#     count = page.all('#new-fields tr').count
#     line_count = page.all('#new-fields tr th.field-form_line').count
#     click_button 'Add Additional Line'
#     sleep(3)
#     expect(page.all('#new-fields tr').count).to eq (count + 3)
#     expect(page.all('#new-fields tr th.field-form_line').count).to eq (line_count + 1)
#     expect(TranscriptionField.count).to eq 3
#   end

#   it "transcribes field-based works" do
#     expect(TranscriptionField.count).to eq 3
#     work = @collection.works.first
#     field_page = work.pages.first
#     expect(TranscriptionField.all.count).to eq 3
#     visit collection_transcribe_page_path(@collection.owner, @collection, work, field_page)
#     expect(TranscriptionField.all.count).to eq 3
#     expect(page).not_to have_content("Autolink")
#     expect(page).to have_content("First field")
#     expect(page).to have_content("Second field")
#     expect(page).to have_content("Third field")
#     page.fill_in('fields_1_First_field', with: "Field one")
#     page.fill_in('fields_2_Second_field', with: "Field < three")
#     page.fill_in('fields_3_Third_field', with: "Field three")
#     find('#save_button_top').click
#     click_button 'Preview', match: :first
#     expect(page.find('.page-preview')).to have_content("First field: Field one")
#     click_button 'Edit', match: :first
#     expect(page.find('.page-editarea')).to have_selector('#fields_1_First_field')
#   end

#   it "deletes a transcription field" do
#     count = TranscriptionField.all.count
#     visit collection_path(@collection.owner, @collection)
#     page.find('.tabs').click_link("Fields")
#     page.find('#new-fields tr[5]').click_link('Delete field')
#     expect(TranscriptionField.all.count).to be < count
#   end

#   it "uses page arrows with unsaved transcription", :js => true do
#     test_page = @collection.works.first.pages.second
#     #next page arrow
#     visit collection_transcribe_page_path(@collection.owner, @collection, test_page.work, test_page)
#     page.fill_in('fields_1_First_field', with: "Field one")
#     message = accept_alert do
#       page.click_link("Next page")
#     end
#     sleep(3)
#     expect(message).to have_content("You have unsaved changes.")
#     visit collection_transcribe_page_path(@collection.owner, @collection, test_page.work, test_page)
#     #previous page arrow - make sure it also works with notes
#     fill_in('Write a new note or ask a question...', with: "Test two")
#     message = accept_alert do
#       page.click_link("Previous page")
#     end
#     sleep(3)
#     expect(message).to have_content("You have unsaved changes.")
#   end

#   #note: these are hidden unless there is table data
#   it "exports a table csv" do
#     work = @collection.works.first
#     visit collection_export_path(@collection.owner, @collection)
#     expect(page).to have_content("Export Individual Works")
#     page.find('tr', text: work.title).find('.btnCsvTblExport').click
#     expect(page.response_headers['Content-Type']).to eq 'application/csv'
#   end

#   it "exports table data for an entire collection" do
#     visit collection_export_path(@collection.owner, @collection)
#     expect(page).to have_content("Export All Tables")
#     page.find('#btnExportTables').click
#     expect(page.response_headers['Content-Type']).to eq 'application/csv'
#   end

#   it "sets collection back to document based transcription" do
#     visit collection_path(@collection.owner, @collection)
#     page.find('.tabs').click_link("Settings")
#     page.click_link("Revert to Document Based Transcription")
#     expect(page).not_to have_selector('a', text: 'Fields')
#   end

# end
