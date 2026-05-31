require 'spec_helper'

describe 'spreadsheet' do
  def set_up_spreadsheet_field(owner, collection)
    visit collection_edit_fields_path(owner, collection)

    # add the spreadsheet
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

  before :each do
    login_as(owner, scope: :user)
  end

  let!(:owner) { create(:owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, field_based: true) }

  describe 'configuration' do
    it 'adds a spreadsheet field to a field-based collection' do
      set_up_spreadsheet_field(owner, collection)

      # verify the spreadsheet configuration button is present
      expect(page).to have_content('Configure Spreadsheet')
    end

    context 'spreadsheet field' do
      it 'configures columns' do
        set_up_spreadsheet_field(owner, collection)
        set_up_columns(owner, collection)
        expect(page).to have_content('Spreadsheet Configuration')
        expect(SpreadsheetColumn.all.count).to eq 2
      end

      it 'skips validation for field-based collections with unbalanced brackets' do
        # This test validates that field-based collections don't run subject linking validation
        # which would otherwise fail on unbalanced brackets like "MEDBREY[[SIC]"

        expect(collection.field_based).to be true

        work = create(:work, collection: collection)
        page = create(:page, work: work)

        expect(page.work).to eq(work)
        expect(page.collection.id).to eq(collection.id)
        expect(page.collection.field_based).to be true

        page.source_text = 'MEDBREY[[SIC] and other [[unbalanced'

        page.validate_source
        expect(page.errors).to be_empty
      end
    end
  end
end
