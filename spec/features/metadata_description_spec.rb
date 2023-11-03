
require 'spec_helper'

describe "Metadata Description" do
  before :all do
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.second

    DatabaseCleaner.start
  end
  before :each do
    login_as(@owner, :scope => :user)
    visit '/feature/description/enable'
  end


  after :all do
    DatabaseCleaner.clean
  end

  # factory code from work spec
  # let(:work_no_ocr){ create(:work, owner_user_id: @owner.id, collection: collection, ocr_correction: false) }
  # let(:page_no_ocr){ create(:page, work: work_no_ocr) }

  # let(:work_ocr)   { create(:work, owner_user_id: @owner.id, collection: collection, ocr_correction: true) }
  # let(:page_ocr)   { create(:page, work: work_ocr) }

  it "Enables and disables", js: true do
    visit edit_collection_path(@owner, @collection)
    page.find('.side-tabs').click_link("Task Configuration")
    page.check("Enable metadata description")
    sleep(1)
    button = page.find_link 'Edit Metadata Form'
    expect(button.disabled?).to be(false)
    expect(Collection.find(@collection.id).data_entry_type).to eq(Collection::DataEntryType::TEXT_AND_METADATA)

    visit edit_collection_path(@owner, @collection)
    page.find('.side-tabs').click_link("Task Configuration")
    page.uncheck("Enable metadata description")
    sleep(1)
    button = page.find_link 'Edit Metadata Form'
    binding.pry
    expect(button.disabled?).to be(true)
    expect(Collection.find(@collection.id).data_entry_type).to eq(Collection::DataEntryType::TEXT_ONLY)
  end


  describe "Owner Flow" do
    before :each do
      login_as(@owner, :scope => :user)
      visit '/feature/description/enable'
    end

    it "edits description fields", js: true do
      visit edit_collection_path(@owner, @collection)
      page.find('.side-tabs').click_link("Task Configuration")
      page.check("Enable metadata description")
      sleep(1)

      visit collection_path(@owner, @collection)
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
      visit collection_path(@owner, @collection)
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

