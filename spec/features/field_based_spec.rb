# frozen_string_literal: true

require 'spec_helper'

describe 'collection field-based transcription settings' do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, :field_based, owner_user_id: owner.id) }
  let(:work) { collection.works.first }
  let(:work_pages) { work.pages.order(:position) }
  let(:first_field) do
    create(:transcription_field, :as_transcription, :text_field,
           collection: collection, label: 'First field', percentage: 20, line_number: 1)
  end
  let(:second_field) do
    create(:transcription_field, :as_transcription,
           collection: collection, label: 'Second field', input_type: 'textarea', line_number: 1)
  end
  let(:third_field) do
    create(:transcription_field, :as_transcription, :select_field,
           collection: collection, label: 'Third field', line_number: 1)
  end

  before do
    login_as(owner, scope: :user)
  end

  after do
    collection.destroy!
    owner.destroy!
  end

  it 'sets a collection to field-based transcription', js: true do
    collection.update!(field_based: false)
    visit collection_path(owner, collection)
    page.find('.tabs').click_link('Settings')
    page.find('.side-tabs').click_link('Task Configuration')

    page.choose('Field-based transcription')
    page.click_link('Edit Fields')

    expect(page).to have_content('Edit Transcription Fields')
    expect(collection.reload).to be_field_based
  end

  it 'edits fields for transcription' do
    expect(collection.transcription_fields).to be_empty
    visit transcription_field_edit_fields_path(collection_id: collection)

    within '#new-fields tr:nth-child(3)' do
      fill_in 'transcription_fields__label', with: 'First field'
      fill_in 'transcription_fields__percentage', with: 20
    end
    within '#new-fields tr:nth-child(4)' do
      fill_in 'transcription_fields__label', with: 'Second field'
      select 'textarea', from: 'transcription_fields__input_type'
    end
    within '#new-fields tr:nth-child(5)' do
      fill_in 'transcription_fields__label', with: 'Third field'
      select 'select', from: 'transcription_fields__input_type'
    end
    click_button 'Save'

    expect(page).to have_content('Select fields must have an options list.')
    fields = collection.transcription_fields.order(:position).reload
    expect(fields.count).to eq(3)
    expect(fields.first.percentage).to eq(20)
    expect(fields.last.input_type).to eq('text')
  end

  it 'highlights only the fields tab on edit fields page' do
    visit transcription_field_edit_fields_path(collection_id: collection)

    within '#collection-tabs .tabs' do
      expect(page).to have_selector('a.active', text: 'Fields')
      expect(page).to have_no_selector('a.active', text: 'Suspicious Behaviors')
    end
  end

  it 'highlights only the suspicious behaviors tab on suspicious behaviors page' do
    visit collection_suspicious_behaviors_path(owner, collection)

    within '#collection-tabs .tabs' do
      expect(page).to have_selector('a.active', text: 'Suspicious Behaviors')
      expect(page).to have_no_selector('a.active', text: 'Fields')
    end
  end

  it 'checks the field preview on the edit page' do
    create_transcription_fields
    visit transcription_field_edit_fields_path(collection_id: collection)

    preview = page.find('div.fields-preview')
    expect(preview).to have_content('First field')
    expect(preview).to have_content('Second field')
    expect(preview).to have_content('Third field')
    expect(page.find('div.fields-preview .field-wrapper:nth-child(1)')[:style]).to include('width: 20%')
    expect(page.find('div.fields-preview .field-wrapper:nth-child(2)')[:style]).not_to include('width: 20%')
  end

  it 'adds a field row without persisting it', js: true do
    create_transcription_fields
    visit transcription_field_edit_fields_path(collection_id: collection)
    count = page.all('#new-fields tr').count

    click_button 'Add Additional Field'

    expect(page.all('#new-fields tr').count).to eq(count + 1)
    expect(collection.transcription_fields.count).to eq(3)
  end

  it 'adds a field line without persisting it', js: true do
    create_transcription_fields
    visit transcription_field_edit_fields_path(collection_id: collection)
    count = page.all('#new-fields tr').count
    line_count = page.all('#new-fields tr th.field-form_line').count

    click_button 'Add Additional Line'

    expect(page).to have_selector('#new-fields tr', count: count + 3)
    expect(page).to have_selector('#new-fields tr th.field-form_line', count: line_count + 1)
    expect(collection.transcription_fields.count).to eq(3)
  end

  it 'keeps unsaved fields visible when moved to another line', js: true do
    visit transcription_field_edit_fields_path(collection_id: collection)

    click_button 'Add Additional Line'
    expect(page).to have_selector('#new-fields tbody', minimum: 2)

    line_two_fields = page.all('#new-fields tbody').last.all('tr.sortable-field')
    line_two_fields.first.fill_in('transcription_fields__label', with: 'Spreadsheet field')
    line_two_fields.first.select('spreadsheet', from: 'transcription_fields__input_type')

    click_button 'Add Additional Field'
    page
      .all('#new-fields tbody')
      .last
      .all('tr.sortable-field')
      .last
      .fill_in('transcription_fields__label', with: 'Moved unsaved field')

    page.execute_script(<<~JS)
      window.__reorderAjaxCallCount = 0;
      window.__fieldEditorReloadCalled = false;
      var originalAjax = $.ajax;
      $.ajax = function() {
        window.__reorderAjaxCallCount += 1;
        return originalAjax.apply($, arguments);
      };
      window.location.reload = function() {
        window.__fieldEditorReloadCalled = true;
      };
    JS

    page.execute_script(<<~JS)
      var $sourceLine = $('#new-fields tbody').eq(1);
      var $destinationLine = $('#new-fields tbody').eq(0);
      var $movedField = $sourceLine.find('tr.sortable-field').last();
      $destinationLine.append($movedField);
      var updateHandler = $destinationLine.sortable('option', 'update');
      updateHandler.call($destinationLine[0], $.Event('sortupdate'), { item: $movedField });
    JS

    moved_field_label = page.find("input[value='Moved unsaved field']", visible: :all)
    moved_field_row = moved_field_label.find(:xpath, './ancestor::tr[1]')

    expect(moved_field_row).to have_selector(
      "input#transcription_fields__line_number[value='1']",
      visible: :all
    )
    expect(page.evaluate_script('window.__reorderAjaxCallCount')).to eq(0)
    expect(page.evaluate_script('window.__fieldEditorReloadCalled')).to be(false)
  end

  it 'transcribes field-based works' do
    create_transcription_fields
    field_page = work_pages.first
    visit collection_transcribe_page_path(owner, collection, work, field_page)

    expect(page).not_to have_content('Autolink')
    expect(page).to have_content('First field')
    expect(page).to have_content('Second field')
    expect(page).to have_content('Third field')
    fill_in field_input_id(first_field), with: 'Field one'
    fill_in field_input_id(second_field), with: 'Field < three'
    select 'Option A', from: field_input_id(third_field)
    find('#save_button_top').click
    click_button 'Preview', match: :first

    expect(page.find('.page-preview')).to have_content('first-field: Field one')
    click_button 'Edit', match: :first
    expect(page.find('.page-editarea')).to have_selector("##{field_input_id(first_field)}")
  end

  it 'handles unbalanced brackets without validation errors' do
    create_transcription_fields
    field_page = work_pages.first
    visit collection_transcribe_page_path(owner, collection, work, field_page)

    fill_in field_input_id(first_field), with: 'MEDBREY[[SIC] - problematic text with unbalanced brackets'
    fill_in field_input_id(second_field), with: 'Another field with [[unbalanced brackets'
    find('#save_button_top').click

    expect(page).not_to have_content('Subject Linking Error')
    expect(page).not_to have_content('500 Internal Server Error')
    expect(page).not_to have_content('undefined method')
    expect(page).to have_content('Saved')
  end

  it 'deletes a transcription field' do
    create_transcription_fields
    visit transcription_field_edit_fields_path(collection_id: collection)

    within(find("input[value='#{third_field.id}']", visible: false).ancestor('tr')) do
      click_link('Delete field')
    end

    expect(collection.transcription_fields.reload).to contain_exactly(first_field, second_field)
  end

  it 'uses page arrows with unsaved transcription', js: true do
    create_transcription_fields
    test_page = work_pages.second
    visit collection_transcribe_page_path(owner, collection, work, test_page)
    fill_in field_input_id(first_field), with: 'Field one'

    message = accept_alert { click_link('Next page') }
    expect(message).to have_content('You have unsaved changes.')

    visit collection_transcribe_page_path(owner, collection, work, test_page)
    fill_in('Write a new note or ask a question...', with: 'Test two')
    message = accept_alert { click_link('Previous page') }

    expect(message).to have_content('You have unsaved changes.')
  end

  it 'exports a table CSV' do
    create_transcription_fields
    work_pages.first.update!(transcription_json: {
                               first_field.id.to_s => 'Field one',
                               second_field.id.to_s => 'Field two',
                               third_field.id.to_s => 'Option A'
                             })
    visit collection_export_path(owner, collection)

    expect(page).to have_content('Export Individual Works')
    page.find('tr', text: work.title).find('.btnCsvTblExport').click

    expect(page.response_headers['Content-Type']).to eq('text/csv')
  end

  it 'sets the collection back to document-based transcription', js: true do
    visit collection_path(owner, collection)
    page.find('.tabs').click_link('Settings')
    page.find('.side-tabs').click_link('Task Configuration')

    page.choose('Document-based transcription')

    expect(page.find_link('Edit Fields')).to match_css('[disabled]')
    expect(page.find_link('Configure Buttons')).not_to match_css('[disabled]')
    expect(collection.reload).not_to be_field_based
  end

  def create_transcription_fields
    first_field
    second_field
    third_field
  end

  def field_input_id(field)
    "fields_#{field.id}_#{field.label.parameterize}"
  end
end
