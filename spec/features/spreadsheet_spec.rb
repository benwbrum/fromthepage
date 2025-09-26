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

  let(:new_work) { create(:work, :with_pages, collection: collection) }

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

      it 'skips validation for field-based collections with unbalanced brackets' do
        # This test validates that field-based collections don't run subject linking validation
        # which would otherwise fail on unbalanced brackets like "MEDBREY[[SIC]"

        # The collection is already field_based: true from the let declaration
        expect(collection.field_based).to be true

        # Create work and manually create pages with proper associations
        work = create(:work, collection: collection)
        page = create(:page, work: work)

        # Verify proper associations - check IDs instead of object identity
        expect(page.work).to eq(work)
        expect(page.collection.id).to eq(collection.id)
        expect(page.collection.field_based).to be true

        # Set problematic text that would fail validation in regular collections
        page.source_text = 'MEDBREY[[SIC] and other [[unbalanced'

        # Validation should be skipped, so no errors should be added
        page.validate_source
        expect(page.errors).to be_empty
      end
    end
  end
end
