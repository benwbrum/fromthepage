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

  let(:new_work) { create(:work, :with_pages, collection: collection) }

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

  describe 'transcription' do
    let!(:spreadsheet_field) do
      create(:transcription_field, :spreadsheet_field,
             collection: collection,
             label: 'Spreadsheet field',
             position: 1,
             starting_rows: 1)
    end
    let!(:spreadsheet_column) do
      create(:spreadsheet_column,
             transcription_field: spreadsheet_field,
             label: 'Text field',
             input_type: 'text',
             position: 1)
    end

    it 'adds a new row when tabbing out of the last populated spreadsheet row', js: true do
      work = create(:work, :with_pages, collection: collection, owner_user_id: owner.id)
      field_page = work.pages.first

      visit collection_transcribe_page_path(collection.owner, collection, work, field_page)

      page.execute_script(<<~JS)
        const element = document.querySelector('[data-controller="handsontable"]');
        const controller = window.Stimulus.getControllerForElementAndIdentifier(element, 'handsontable');

        controller._handsontable.selectCell(0, 0);
        controller._handsontable.listen();
      JS
      page.driver.browser.action.send_keys('Row 1', :tab).perform

      Timeout.timeout(Capybara.default_max_wait_time) do
        loop do
          row_count = page.evaluate_script(<<~JS)
            const element = document.querySelector('[data-controller="handsontable"]');
            const controller = window.Stimulus.getControllerForElementAndIdentifier(element, 'handsontable');

            controller._handsontable.countRows();
          JS

          break if row_count == 2

          sleep 0.1
        end
      end

      row_data = page.evaluate_script(<<~JS)
        const element = document.querySelector('[data-controller="handsontable"]');
        const controller = window.Stimulus.getControllerForElementAndIdentifier(element, 'handsontable');

        controller._handsontable.getData();
      JS

      expect(row_data.length).to eq 2
      expect(row_data.first.first).to eq 'Row 1'
      expect(row_data.last.first).to be_nil
    end
  end
end
