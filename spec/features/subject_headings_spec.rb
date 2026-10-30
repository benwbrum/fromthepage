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
      expect(page).to have_unchecked_field('Check headings against Library of Congress authorities')
      attach_file 'CSV inventory', file.path
      fill_in 'Instructions for AI Draft Metadata', with: 'Use broad topics.'
      click_button 'Import Headings'
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
      attach_file 'Replace CSV inventory', file.path
      check 'Check headings against Library of Congress authorities'
      click_button 'Save / Import Headings'
    end
    expect(page).to have_content('3 imported rows; 2 unique headings.')
    expect(page).to have_content('Validation status: Queued')
    expect(SubjectHeadingInventory.exists?(original.id)).to be(false)
    expect(field.reload.subject_heading_inventory.subject_headings.pluck(:heading)).to contain_exactly('Replacement', 'Different')
  end
end
