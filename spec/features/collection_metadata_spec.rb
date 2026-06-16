# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'collection metadata' do
  include ActiveJob::TestHelper

  let(:owner) { create(:unique_user, :owner) }
  let(:collection_title) { "ladi-#{SecureRandom.hex(4)}" }
  let(:metadata_csv_path) { Rails.root.join('test_data/uploads/eaacone_metadata_FromThePage_TestDataset.csv') }

  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
  end

  after do |example|
    clear_enqueued_jobs
    clear_performed_jobs

    if example.metadata[:js]
      owner.all_owner_collections.each(&:destroy!)
      owner.destroy!
    else
      DatabaseCleaner.clean
    end
  end

  def create_metadata_collection
    collection = create(:collection, owner_user_id: owner.id, title: collection_title, works: [])

    %w[eaacone_c1955-01 eaacone_c1975-01 eaacone_c1977-01].each do |filename|
      create(:work, owner: owner, collection: collection, uploaded_filename: filename)
    end

    collection.works.reset
    collection
  end

  def create_faceted_collection(facets_enabled: true)
    collection = create_metadata_collection
    create_metadata_coverage(collection, 'filename', 3)
    create_metadata_coverage(collection, 'field_identifier_local', 3)
    collection.update!(facets_enabled: facets_enabled)
    collection
  end

  def create_metadata_coverage(collection, key, count)
    coverage = collection.metadata_coverages.create!(key: key, count: count)
    coverage.create_facet_config!(input_type: 'text')
    coverage
  end

  def upload_metadata_file(collection)
    visit collection_metadata_upload_path(collection)
    expect(page).to have_content('To update metadata for several works within this collection')

    attach_file(
      'metadata_file',
      metadata_csv_path,
      make_visible: true
    )

    click_button('Upload')
    expect(page).to have_content('Your upload is being processed. An email will be sent to update its status')
    perform_enqueued_jobs
  end

  it 'creates a collection as owner' do
    login_as owner
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: collection_title
    click_button('Create Collection')
    expect(page).to have_content(collection_title)
  end

  it 'uploads works from a zip file', js: true do
    login_as owner
    collection = create(:collection, owner_user_id: owner.id, title: collection_title, works: [])
    visit dashboard_owner_path
    page.find('.tabs').click_link('Start A Project')
    page.find(:css, '#document-upload').click
    select2_select(id: 'document_upload_collection_id', value: collection.title)

    attach_file(
      'document_upload_file',
      Rails.root.join('test_data/uploads/ladi_fixture.zip'),
      make_visible: true
    )
    click_button('Upload File')

    expect(page).to have_content('Document has been uploaded')
    expect(find('h1').text).to eq collection_title
    wait_for_upload_processing
    expect(Collection.find_by(title: collection_title).works).not_to be_empty
  end

  it 'uploads metadata for the imported works', js: true do
    login_as owner
    collection = create_metadata_collection
    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Look & Feel')
    expect(page).to have_content('Allow users to browse works within this collection via metadata.')

    upload_metadata_file(collection)

    filename = collection.metadata_coverages.where(key: 'filename').first
    expect(filename.count).to eq 3
  end

  it 'increments occurrences as works are re-imported', js: true do
    login_as owner
    collection = create_metadata_collection
    File.open(metadata_csv_path) do |metadata_file|
      Work::Metadata::ImportCsv.new(metadata_file: metadata_file, collection: collection).perform
    end
    filename = collection.metadata_coverages.where(key: 'filename').first
    expect(filename.count).to eq 3

    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Look & Feel')
    expect(page).to have_content('Allow users to browse works within this collection via metadata.')

    upload_metadata_file(collection)

    filename.reload
    expect(filename.count).to eq 3
  end

  it 'enables facets', js: true do
    login_as owner
    collection = create_faceted_collection(facets_enabled: false)
    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Look & Feel')
    page.check('Enable metadata facets')
    expect(page).to have_content('Collection has been updated')
    page.click_link('Edit Facets')
    expect(page).to have_content('Metadata Facets')
    facets_description = 'Configure metadata facets by reviewing the metadata in your collection ' \
                         'and labelling fields to be displayed to transcribers.'
    expect(page).to have_content(facets_description)
    expect(page).to have_content('filename')
    expect(page).to have_content('field_identifier_local')
  end

  it 'allows saving additional metadata' do
    login_as owner
    collection = create_faceted_collection
    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Look & Feel')
    click_link 'Edit Facets'
    expect(page).to have_content('Metadata Facets')
    expect(page).to have_content('filename')
    fill_in 'metadata_filename_label', with: 'Filename'
    fill_in 'metadata_filename_order', with: 9
    click_button 'Save Metadata'
    expect(page).to have_content('Collection facets updated successfully')
    expect(find_field('metadata_filename_label').value).to eq 'Filename'
    expect(find_field('metadata_filename_order').value).to eq '0'
  end

  it 'allows a numeric value from 0 to 9 for text type' do
    login_as owner
    collection = create_faceted_collection
    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Look & Feel')
    click_link 'Edit Facets'
    expect(page).to have_content('Metadata Facets')
    expect(page).to have_content('filename')
    fill_in 'metadata_filename_label', with: 'Filename'
    fill_in 'metadata_filename_order', with: 25
    click_button 'Save Metadata'
    expect(page).to have_content('Order is not included in the list')
  end

  it 'allows a numeric value from 0 to 2 for date type' do
    login_as owner
    collection = create_faceted_collection
    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Look & Feel')
    click_link 'Edit Facets'
    expect(page).to have_content('Metadata Facets')
    expect(page).to have_content('filename')
    fill_in 'metadata_filename_label', with: 'Filename'
    select('date', from: 'metadata_filename_input_type')
    fill_in 'metadata_filename_order', with: 3
    click_button 'Save Metadata'
    expect(page).to have_content('Order is not included in the list')
  end

  it "can't enter an order as a string" do
    login_as owner
    collection = create_faceted_collection
    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Look & Feel')
    click_link 'Edit Facets'
    expect(page).to have_content('Metadata Facets')
    expect(page).to have_content('filename')
    fill_in 'metadata_filename_label', with: 'Filename'
    fill_in 'metadata_filename_order', with: 'foo'
    click_button 'Save Metadata'
    expect(page).to have_content('Order is not a number')
  end

  it 'should not be available/visible for the Individual Researcher plan', js: true do
    owner.update!(account_type: 'Individual Researcher')
    login_as owner
    collection = create_faceted_collection
    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Look & Feel')
    expect(page).to have_field('Enable metadata facets', disabled: true)
    expect(page.find_link('Edit Facets')).to match_css('[disabled]')
    expect(page).to have_content('Not available for researcher accounts.')
  end

  it 'deletes a collection' do
    login_as owner
    collection = create_faceted_collection
    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Danger Zone')
    expect(page).to have_content(collection.title)
    expect(page).to have_content('Please use caution')
    click_link 'Delete Collection'
    expect(page).not_to have_content(collection.title)
    expect(MetadataCoverage.where(collection_id: collection.id)).to be_empty
  end
end
