require 'spec_helper'

def set_up_spreadsheet_field(owner, collection)
  visit collection_edit_fields_path(owner, collection)
  # add the spreadhseet
  page.find('#new-fields tr[3]').fill_in('transcription_fields__label', with: 'Spreadsheet field')
  page.find('#new-fields tr[3]').select('spreadsheet', from: 'transcription_fields__input_type')
  # hit save
  click_button 'Save'
end

def set_up_columns(owner, collection)
  visit collection_edit_fields_path(owner, collection)
  click_link 'Configure Spreadsheet'

  page.find('#new-columns tr[2]').fill_in('spreadsheet_columns__label', with: 'Text field')
  page.find('#new-columns tr[2]').select('text', from: 'spreadsheet_columns__input_type')
  page.find('#new-columns tr[3]').fill_in('spreadsheet_columns__label', with: 'Date field')
  page.find('#new-columns tr[3]').select('date', from: 'spreadsheet_columns__input_type')
  # hit save
  click_button 'Save'
end


describe "spreadsheet" do
  before :all do
    DatabaseCleaner.start
  end
  after :all do
    DatabaseCleaner.clean
  end
  before :each do
    login_as(owner, scope: :user)
  end


  let(:user)  { create(:user, email: 'new@example.org') }
  let(:owner) { create(:owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, field_based: true) }

  let(:new_work) { create(:work, :with_pages, collection_id: collection.id) }

  describe 'configuration' do
    it 'adds a spreadsheet field to a field-based collection' do
      set_up_spreadsheet_field(owner, collection)

      # verify the spreadhseet configuration button is present
      expect(page).to have_content("Configure Spreadsheet")
    end


    context 'spreadsheet field' do
      it 'configures columns' do
        set_up_spreadsheet_field(owner, collection)
        set_up_columns(owner, collection)
        expect(page).to have_content("Spreadsheet Configuration")
        expect(SpreadsheetColumn.all.count).to eq 2
      end

      it 'handles unbalanced brackets in spreadsheet cells without validation errors' do
        # Create a simple test to debug validation
        test_collection = create(:collection, field_based: true, subjects_disabled: false)
        expect(test_collection.field_based).to be true
        expect(test_collection.subjects_disabled).to be false

        test_work = create(:work, collection: test_collection)
        expect(test_work.collection).to eq(test_collection)

        test_page = create(:page, work: test_work)
        expect(test_page.work).to eq(test_work)
        expect(test_page.collection).to eq(test_collection)

        # Test the exact condition from validate_source
        condition_result = test_page.collection&.field_based || test_page.collection&.subjects_disabled
        expect(condition_result).to be true, "Expected condition to be true, got: field_based=#{test_page.collection&.field_based}, subjects_disabled=#{test_page.collection&.subjects_disabled}"

        # Set problematic source text that would normally trigger validation errors
        test_page.source_text = 'MEDBREY[[SIC] and other [[unbalanced'
        expect(test_page.source_text).not_to be_blank

        # Use Rails validation framework instead of calling method directly
        is_valid = test_page.valid?

        # Expect validation to pass (no errors)
        expect(is_valid).to be true, "Expected page to be valid, but got errors: #{test_page.errors.full_messages.inspect}"
        expect(test_page.errors).to be_empty, "Expected no errors, but got: #{test_page.errors.full_messages.inspect}"
      end
    end
  end
end
