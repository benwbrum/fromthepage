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

  def handsontable_expression(method_call)
    "window.Stimulus.getControllerForElementAndIdentifier(document.querySelector('[data-controller=\"handsontable\"]'), 'handsontable')._handsontable.#{method_call}"
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

      page.execute_script("#{handsontable_expression('selectCell(0, 0)')}; #{handsontable_expression('listen()')};")
      page.driver.browser.action.send_keys('Row 1', :tab).perform

      Timeout.timeout(Capybara.default_max_wait_time) do
        loop do
          row_count = page.evaluate_script(handsontable_expression('countRows()'))

          break if row_count == 2

          sleep 0.1
        end
      end

      row_data = page.evaluate_script(handsontable_expression('getData()'))

      expect(row_data.length).to eq 2
      expect(row_data.first.first).to eq 'Row 1'
      expect(row_data.last.first).to be_nil
    end

    context 'AI draft' do
      let!(:work) { create(:work, :with_pages, collection: collection, owner_user_id: owner.id) }
      let!(:field_page) { work.pages.first }

      it 'fills the spreadsheet grid from a single AI engine draft', js: true do
        create(:ai_transcription,
               page: field_page,
               model: 'gemini-3.1-pro-preview',
               status: 'finished',
               transcription_json: { spreadsheet_field.id.to_s => [{ spreadsheet_column.id.to_s => 'AI drafted value' }] })

        visit collection_transcribe_page_path(collection.owner, collection, work, field_page)

        find('#ai-draft-fields').click

        Timeout.timeout(Capybara.default_max_wait_time) do
          loop do
            break if page.evaluate_script(handsontable_expression('getDataAtCell(0, 0)')) == 'AI drafted value'

            sleep 0.1
          end
        end

        expect(find('#ai-draft-fields')).to be_disabled
      end

      it 'shows a disagreement panel and lets the user switch AI engines', js: true do
        create(:ai_transcription,
               page: field_page,
               model: 'gemini-3.1-pro-preview',
               status: 'finished',
               transcription_json: { spreadsheet_field.id.to_s => [{ spreadsheet_column.id.to_s => 'Gemini value' }] })
        create(:ai_transcription,
               page: field_page,
               model: 'claude-opus-4',
               status: 'finished',
               transcription_json: { spreadsheet_field.id.to_s => [{ spreadsheet_column.id.to_s => 'Claude value' }] })

        visit collection_transcribe_page_path(collection.owner, collection, work, field_page)

        find('#ai-draft-fields').click

        disagree_panel = find('.ai-draft-disagree-spreadsheet')
        expect(disagree_panel).to have_content('claude-opus-4')
        expect(disagree_panel).to have_content('gemini-3.1-pro-preview')

        expect(page.evaluate_script(handsontable_expression('getDataAtCell(0, 0)'))).to eq 'Claude value'

        disagree_panel.find('.ai-draft-option', text: 'gemini-3.1-pro-preview').click

        Timeout.timeout(Capybara.default_max_wait_time) do
          loop do
            break if page.evaluate_script(handsontable_expression('getDataAtCell(0, 0)')) == 'Gemini value'

            sleep 0.1
          end
        end
      end
    end
  end
end
