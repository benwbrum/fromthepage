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
    expect(page).to have_css('.litebox-embed input[type="file"]')
    file = Tempfile.new(['subjects', '.csv'])
    rows = ['Agriculture,https://id.loc.gov/authorities/subjects/sh85002415'] + 2999.times.map { |i| "Legacy topic #{i}," }
    file.write("heading,uri\n#{rows.join("\n")}\n")
    file.rewind
    within('.litebox-embed') do
      expect(page).to have_unchecked_field('Check for matches in Library of Congress authority records')
      attach_file 'Subject headings file', file.path
      fill_in 'Subject assignment guidelines (optional)', with: 'Use broad topics.'
      click_button 'Save Subject Headings'
    end
    expect(page).to have_content('3000 imported rows; 3000 unique headings.')
    expect(page).to have_content('Validation status: Not requested')
    expect(field.reload.subject_heading_instructions).to eq('Use broad topics.')
    expect(field.subject_heading_inventory.subject_headings.find_by(heading: 'Agriculture').uri).to eq('https://id.loc.gov/authorities/subjects/sh85002415')
  end

  it 'replaces a configured inventory and requests advisory checking' do
    original = import_headings(field)
    visit collection_subject_headings_path(owner, collection, field)
    expect(page).to have_content('1 imported rows; 1 unique headings.')
    file = Tempfile.new(['replacement', '.csv'])
    file.write("heading\nReplacement\nReplacement.\nDifferent\n")
    file.rewind
    within('.litebox-embed') do
      attach_file 'Subject headings file', file.path
      check 'Check for matches in Library of Congress authority records'
      click_button 'Save Subject Headings'
    end
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
    expect(find('#instructions')[:rows]).to eq('5')
    fill_in 'Subject assignment guidelines (optional)', with: 'Unsaved guideline'
    page.current_window.resize_to(390, 844)
    expect(page.evaluate_script("document.querySelector('.subject-heading-configuration').getBoundingClientRect().right <= window.innerWidth")).to be(true)
    click_button 'Cancel'
    expect(page).not_to have_css('.litebox.visible')
    expect(field.reload.subject_heading_instructions).to be_nil
    expect(field.subject_heading_inventory).to be_nil
  ensure
    page.current_window.resize_to(1200, 900)
  end

  it 'saves guidelines without a new file and keeps the separate authority retry action' do
    original = import_headings(field)
    visit collection_subject_headings_path(owner, collection, field)
    expect(page.evaluate_script("document.getElementById('file').required")).to be(false)
    expect(page).to have_content('Replacing this file changes which headings are available for future assignments. Headings already saved to item descriptions will not be changed.')
    fill_in 'Subject assignment guidelines (optional)', with: 'Prefer local cataloging conventions.'
    click_button 'Save Subject Headings'
    expect(page).to have_field('Subject assignment guidelines (optional)', with: 'Prefer local cataloging conventions.')
    expect(field.reload.subject_heading_inventory.id).to eq(original.id)
    click_button 'Check authorities again'
    expect(page).to have_content('Validation status: Queued')
    expect(field.reload.subject_heading_inventory.id).to eq(original.id)
  end
end
