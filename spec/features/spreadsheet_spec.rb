require 'spec_helper'

def set_up_spreadsheet_field(owner, collection)
  visit collection_edit_fields_path(owner, collection)

  # add the spreadhseet
  page.all('#new-fields tr')[2].fill_in('transcription_fields__label', with: 'Spreadsheet field')
  page.all('#new-fields tr')[2].select('spreadsheet', from: 'transcription_fields__input_type')

  # hit save
  click_button 'Save'
end

def set_up_columns(owner, collection)
  visit collection_edit_fields_path(owner, collection)
  click_link 'Configure Spreadsheet'

  rows = page.all('#new-columns tr')

  # Set up the text field
  rows[1].fill_in('spreadsheet_columns__label', with: 'Text field')
  rows[1].select('text', from: 'spreadsheet_columns__input_type')

  # Set up the date field
  rows[2].fill_in('spreadsheet_columns__label', with: 'Date field')
  rows[2].select('date', from: 'spreadsheet_columns__input_type')

  # hit save
  click_button 'Save'
end

describe 'spreadsheet' do
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
      expect(page).to have_content('Configure Spreadsheet')
    end

    context 'spreadsheet field' do
      it 'configures columns' do
        set_up_spreadsheet_field(owner, collection)
        set_up_columns(owner, collection)
        expect(page).to have_content('Spreadsheet Configuration')
        expect(SpreadsheetColumn.all.count).to eq 2
      end
    end
  end
end
