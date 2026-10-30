require 'spec_helper'

describe 'Project owner subject heading configuration', js: true do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: [], data_entry_type: Collection::DataEntryType::TEXT_AND_METADATA) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: collection, label: 'Topics', input_type: 'subject_headings', line_number: 1) }

  before do
    Current.user = owner
    login_as owner
    @original_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    ActiveJob::Base.queue_adapter = @original_queue_adapter
    collection.destroy!
    owner.destroy!
  end

  it 'opens configuration from the field editor and imports 3,000 headings through the modal' do
    visit collection_edit_metadata_fields_path(owner, collection)
    click_link 'Configure Subject Headings'
    expect(page).to have_button('Browse')
    file = Tempfile.new(['subjects', '.csv'])
    rows = ['Agriculture,https://id.loc.gov/authorities/subjects/sh85002415'] + 2999.times.map { |i| "Legacy topic #{i}," }
    file.write("heading,uri\n#{rows.join("\n")}\n")
    file.rewind
    within('.litebox-embed') do
      expect(page).to have_unchecked_field('Check for matches in Library of Congress authority records')
      attach_file 'Subject headings file', file.path, make_visible: true
      expect(find('.input-file input[type="text"]').value).to end_with(File.basename(file.path))
      fill_in 'Subject assignment guidelines (optional)', with: 'Use broad topics.'
      click_button 'Save Subject Headings'
    end
    expect(page).to have_current_path(collection_edit_metadata_fields_path(owner, collection))
    expect(page).not_to have_css('.litebox.visible')
    expect(page).to have_css('.flash-notice', text: 'Subject headings saved.')
    expect(page).to have_css('.subject-heading-count', text: '3000 headings configured')
    click_link 'Configure Subject Headings'
    expect(page).to have_content('3000 imported rows; 3000 unique headings.')
    expect(page).to have_content('Validation status: Not requested')
    expect(field.reload.subject_heading_instructions).to eq('Use broad topics.')
    expect(field.subject_heading_inventory.subject_headings.find_by(heading: 'Agriculture').uri).to eq('https://id.loc.gov/authorities/subjects/sh85002415')
  end

  it 'shows invalid uploads using the standard modal validation styling' do
    visit collection_edit_metadata_fields_path(owner, collection)
    click_link 'Configure Subject Headings'
    file = Tempfile.new(['invalid-subjects', '.csv'])
    file.write("subject\nAgriculture\n")
    file.rewind
    within('.litebox-embed') do
      fill_in 'Subject assignment guidelines (optional)', with: 'Keep these guidelines.'
      attach_file 'Subject headings file', file.path, make_visible: true
      click_button 'Save Subject Headings'
      error = find('.validation[role="alert"]')
      expect(error).to have_css('.validation_summary li', text: 'CSV requires a heading column.')
      expect(error.style('border-left-width')['border-left-width']).to eq('3px')
      expect(page).to have_field('Subject assignment guidelines (optional)', with: 'Keep these guidelines.')
      expect(page).to have_button('Save Subject Headings')
    end
    expect(field.reload.subject_heading_inventory).to be_nil
  ensure
    file&.close!
  end

  it 'replaces a configured inventory and requests advisory checking' do
    original = import_headings(field)
    visit collection_subject_headings_path(owner, collection, field)
    expect(page).to have_content('1 imported rows; 1 unique headings.')
    expect(page).to have_button('Run authority check')
    expect(page).not_to have_field('Check for matches in Library of Congress authority records')
    file = Tempfile.new(['replacement', '.csv'])
    file.write("heading\nReplacement\nReplacement.\nDifferent\n")
    file.rewind
    within('.litebox-embed') do
      attach_file 'Subject headings file', file.path, make_visible: true
      expect(page).not_to have_button('Run authority check')
      expect(page).to have_content('Select this option, then click Save Subject Headings to check the uploaded file.')
      check 'Check for matches in Library of Congress authority records'
      click_button 'Save Subject Headings'
    end
    expect(page).to have_current_path(collection_edit_metadata_fields_path(owner, collection))
    expect(page).to have_css('.flash-notice', text: 'Subject headings saved.')
    expect(page).to have_css('.subject-heading-count', text: '2 headings configured')
    click_link 'Configure Subject Headings'
    expect(page).to have_content('3 imported rows; 2 unique headings.')
    expect(page).to have_content('Validation status: Queued')
    expect(SubjectHeadingInventory.exists?(original.id)).to be(false)
    expect(field.reload.subject_heading_inventory.subject_headings.pluck(:heading)).to contain_exactly('Replacement', 'Different')
  end

  it 'fits desktop and mobile screens and cancels guideline edits without saving' do
    visit collection_edit_metadata_fields_path(owner, collection)
    click_link 'Configure Subject Headings'
    dialog = find('.litebox-embed.subject-heading-configuration')
    expect(dialog.rect.width).to be_between(650, 750)
    expect(dialog).to have_css('.subject-heading-section', count: 3)
    expect(find_button('Save Subject Headings').rect.height).to eq(find_button('Browse').rect.height)
    expect(find_button('Cancel').rect.height).to eq(find_button('Browse').rect.height)
    expect(find('#instructions')[:rows]).to eq('5')
    fill_in 'Subject assignment guidelines (optional)', with: 'Unsaved guideline'
    page.current_window.resize_to(390, 844)
    expect(page.evaluate_script("document.querySelector('.subject-heading-configuration').getBoundingClientRect().right <= window.innerWidth")).to be(true)
    expect(page.evaluate_script("Array.from(document.querySelectorAll('.subject-heading-configuration button')).every(button => button.scrollWidth <= button.clientWidth && button.getBoundingClientRect().right <= window.innerWidth)")).to be(true)
    click_button 'Cancel'
    expect(page).not_to have_css('.litebox.visible')
    expect(field.reload.subject_heading_instructions).to be_nil
    expect(field.subject_heading_inventory).to be_nil
  ensure
    page.current_window.resize_to(1200, 900)
  end

  it 'saves guidelines without a new file and keeps the separate authority retry action' do
    original = import_headings(field)
    visit collection_edit_metadata_fields_path(owner, collection)
    click_link 'Configure Subject Headings'
    expect(find('#file', visible: :all).evaluate_script('this.required')).to be(false)
    expect(page).to have_content('Replacing this file changes which headings are available for future assignments. Headings already saved to item descriptions will not be changed.')
    fill_in 'Subject assignment guidelines (optional)', with: 'Prefer local cataloging conventions.'
    click_button 'Save Subject Headings'
    expect(page).to have_current_path(collection_edit_metadata_fields_path(owner, collection))
    expect(page).not_to have_css('.litebox.visible')
    expect(page).to have_css('.flash-notice', text: 'Subject headings saved.')
    click_link 'Configure Subject Headings'
    expect(page).to have_field('Subject assignment guidelines (optional)', with: 'Prefer local cataloging conventions.')
    expect(field.reload.subject_heading_inventory.id).to eq(original.id)
    expect(page).not_to have_field('Check for matches in Library of Congress authority records')
    click_button 'Run authority check'
    expect(page).to have_content('Validation status: Queued')
    expect(page).to have_button('Authority check queued', disabled: true)
    expect(page).not_to have_button('Run authority check')
    expect(page).not_to have_field('Check for matches in Library of Congress authority records')
    expect(field.reload.subject_heading_inventory.id).to eq(original.id)
  end

  it 'previews searchable multiple selections and saves them on a work' do
    import_headings(field, "heading\nAgriculture\nAbolitionists\nLocal history\n")
    visit collection_edit_metadata_fields_path(owner, collection)
    expect(page).to have_css('.subject-heading-count', text: '3 headings configured')
    within('.field-wrapper') do
      find('.select2-search__field').set('agri')
    end
    expect(page).to have_css('.select2-results__option', text: 'Agriculture')
    expect(page).not_to have_css('.select2-results__option', text: 'Abolitionists')
    find('.select2-results__option', text: 'Agriculture', exact_text: true).click
    find('.field-wrapper .select2-search__field').set('abol')
    find('.select2-results__option', text: 'Abolitionists', exact_text: true).click
    expect(find('.field-wrapper select', visible: :all).value).to contain_exactly('Agriculture', 'Abolitionists')

    work = create(:work_with_pages, collection: collection, owner: owner, owner_user_id: owner.id)
    visit describe_collection_work_path(owner, collection, work)
    find('.field-wrapper .select2-search__field').set('agri')
    find('.select2-results__option', text: 'Agriculture', exact_text: true).click
    find('.field-wrapper .select2-search__field').set('abol')
    find('.select2-results__option', text: 'Abolitionists', exact_text: true).click
    click_button 'save_button_top'
    expect(page).to have_css('.select2-selection__choice', count: 2)
    values = JSON.parse(work.reload.metadata_description).find { |entry| entry['transcription_field_id'] == field.id }['value']
    expect(values).to contain_exactly('Agriculture', 'Abolitionists')

    import_headings(field, "heading\nReplacement\n")
    visit describe_collection_work_path(owner, collection, work)
    expect(find('.field-wrapper select', visible: :all).value).to contain_exactly('Agriculture', 'Abolitionists')
    expect(page).to have_css('.select2-selection__choice', count: 2)
    click_button 'save_button_top'
    expect(JSON.parse(work.reload.metadata_description).first['value']).to contain_exactly('Agriculture', 'Abolitionists')
  end
end
