require 'spec_helper'

describe 'Subject heading metadata controls', js: true do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: [], data_entry_type: Collection::DataEntryType::TEXT_AND_METADATA) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: collection, label: 'Topics', input_type: 'subject_headings', line_number: 1) }
  let!(:work) { create(:work, collection: collection, owner: owner) }
  let!(:image_page) { create(:page, work: work) }

  before do
    Current.user = owner
    login_as owner
  end

  after do
    collection.destroy!
    owner.destroy!
  end

  def select_heading(text)
    find('.subject-heading-input + .select2 .select2-selection').click
    find('.select2-container--open .select2-search__field').set(text)
    find('.select2-results__option', exact_text: text).click
  end

  it 'searches 3,000 headings, saves multiple selections, and retains retired values' do
    rows = 2998.times.map { |i| "Legacy topic #{i}," }
    inventory = import_headings(field, "heading,uri\nAgriculture,https://id.loc.gov/authorities/subjects/sh85002415\nFarmers,\n#{rows.join("\n")}\n")
    visit describe_collection_work_path(owner, collection, work)
    expect(page).to have_css('.subject-heading-input + .select2')
    expect(page.all('.subject-heading-input option', visible: :all).size).to eq(0)
    select_heading('Agriculture')
    select_heading('Farmers')
    find('#save_button_top').click
    expect(page).to have_current_path(save_description_collection_work_path(owner, collection, work))
    expect(JSON.parse(work.reload.metadata_description).first['value'].map { |v| v['heading'] }).to contain_exactly('Agriculture', 'Farmers')
    expect(page.all('.subject-heading-input option', visible: :all).size).to eq(2)
    import_headings(field, "heading\nReplacement\n")
    visit describe_collection_work_path(owner, collection, work)
    expect(page).to have_content('Agriculture')
    expect(page).to have_content('Farmers')
    expect(page).to have_content('https://id.loc.gov/authorities/subjects/sh85002415')
    expect(SubjectHeadingInventory.exists?(inventory.id)).to be(false)
  end

  it 'applies a reviewed subject draft through the existing AI button and Save action' do
    option = import_headings(field).subject_headings.first
    create(:ai_work_metadata, work_id: work.id, model: 'gemini-3.7-flash', status: :finished, metadata_json: { field.id.to_s => [option.snapshot] })
    visit describe_collection_work_path(owner, collection, work)
    find('#ai-draft-metadata-fields').click
    expect(page).to have_css('.select2-selection__choice', text: 'Agriculture')
    expect(work.reload.metadata_description).to be_nil
    find('#save_button_top').click
    expect(page).to have_current_path(save_description_collection_work_path(owner, collection, work))
    expect(JSON.parse(work.reload.metadata_description).first['value']).to eq([option.snapshot])
  end

  it 'allows staff to choose between disagreeing AI subject drafts' do
    inventory = import_headings(field, "heading\nAgriculture\nFarmers\n")
    options = inventory.subject_headings.order(:id).to_a
    %w[gemini-3.7-flash claude-sonnet-4-6].each_with_index do |model, index|
      create(:ai_work_metadata, work_id: work.id, model: model, status: :finished, metadata_json: { field.id.to_s => [options[index].snapshot] })
    end
    visit describe_collection_work_path(owner, collection, work)
    find('#ai-draft-metadata-fields').click
    find('.ai-draft-option', text: 'Farmers').click
    expect(page).to have_css('.select2-selection__choice', text: 'Farmers')
    expect(work.reload.metadata_description).to be_nil
    find('#save_button_top').click
    expect(page).to have_current_path(save_description_collection_work_path(owner, collection, work))
    expect(JSON.parse(work.reload.metadata_description).first['value']).to eq([options.last.snapshot])
  end

  it 'opens configuration from the field editor and uploads a CSV through the modal' do
    visit collection_edit_metadata_fields_path(owner, collection)
    click_link 'Configure Subject Headings'
    expect(page).to have_css('.litebox-embed input[type="file"]')
    file = Tempfile.new(['subjects', '.csv'])
    file.write("heading\nAgriculture\n")
    file.rewind
    within('.litebox-embed') do
      attach_file 'CSV inventory', file.path
      fill_in 'Instructions for AI Draft Metadata', with: 'Use broad topics.'
      click_button 'Import Headings'
    end
    expect(page).to have_content('1 imported rows; 1 unique selectable headings.')
    expect(field.reload.subject_heading_instructions).to eq('Use broad topics.')
  end
end
