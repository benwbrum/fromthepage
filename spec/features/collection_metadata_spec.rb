require 'spec_helper'

RSpec.describe 'collection metadata', order: :defined do
  include ActiveJob::TestHelper

  let(:collection_title) { "ladi-#{SecureRandom.hex(4)}" }
  let(:metadata_keys) { %w[filename field_identifier_local] }

  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
    @owner = create(:unique_user, :owner, account_type: 'Small Organization')
    @user = create(:unique_user)
  end

  after do |example|
    clear_enqueued_jobs
    clear_performed_jobs
    Current.user = nil
    logout

    if example.metadata[:js]
      Collection.where(owner_user_id: @owner.id).find_each(&:destroy!) if @owner&.persisted?
    else
      DatabaseCleaner.clean
    end
  end

  def create_metadata_collection(title: collection_title, owner: @owner)
    collection = create(:collection, owner_user_id: owner.id, title: title, works: [])
    metadata_keys.each do |key|
      metadata_coverage = create(:metadata_coverage, collection: collection, key: key, count: 3)
      create(:facet_config, metadata_coverage: metadata_coverage)
    end
    collection
  end

  def create_importable_collection(title: collection_title, owner: @owner)
    collection = create(:collection, owner_user_id: owner.id, title: title, works: [])
    %w[eaacone_c1955-01 eaacone_c1975-01 eaacone_c1977-01].each do |identifier|
      create(:work, owner: owner, owner_user_id: owner.id, collection: collection, title: identifier, identifier: identifier)
    end
    collection
  end

  it 'creates a collection as owner' do
    login_as @owner
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: collection_title
    click_button('Create Collection')
    expect(page).to have_content(collection_title)
  end

  it 'uploads works from a zip file', js: true do
    create(:collection, owner_user_id: @owner.id, title: collection_title, works: [])

    login_as @owner
    visit dashboard_owner_path
    page.find('.tabs').click_link('Start A Project')
    page.find(:css, '#document-upload').click
    select2_select(id: 'document_upload_collection_id', value: collection_title)

    attach_file(
      'document_upload_file',
      Rails.root.join('test_data/uploads/ladi_fixture.zip'),
      make_visible: true
    )
    sleep 2
    click_button('Upload File')

    expect(page).to have_content('Document has been uploaded')
    title = find('h1').text
    expect(title).to eq collection_title
    wait_for_upload_processing
    sleep(10)
  end

  it 'uploads metadata for the imported works', js: true do
    c = create_importable_collection

    login_as @owner
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Look & Feel')
    expect(page).to have_content('Allow users to browse works within this collection via metadata.')
    visit collection_metadata_upload_path(c)
    expect(page).to have_content('To update metadata for several works within this collection')

    attach_file(
      'metadata_file',
      Rails.root.join('test_data/uploads/eaacone_metadata_FromThePage_TestDataset.csv'),
      make_visible: true
    )

    click_button('Upload')
    expect(page).to have_content('Your upload is being processed. An email will be sent to update its status')
    perform_enqueued_jobs
  end

  it 'increments occurrences as works are re-imported', js: true do
    c = create_importable_collection
    filename = create(:metadata_coverage, collection: c, key: 'filename', count: 3)
    create(:facet_config, metadata_coverage: filename)

    login_as @owner
    expect(filename.count).to eq 3

    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Look & Feel')
    expect(page).to have_content('Allow users to browse works within this collection via metadata.')
    visit collection_metadata_upload_path(c)
    expect(page).to have_content('To update metadata for several works within this collection')

    script = "$('#metadata_file').css({opacity: 100, display: 'block', position: 'relative', left: ''});"
    page.execute_script(script)

    attach_file(
      'metadata_file',
      Rails.root.join('test_data/uploads/eaacone_metadata_FromThePage_TestDataset.csv'),
      make_visible: true
    )

    click_button('Upload')
    expect(page).to have_content('Your upload is being processed. An email will be sent to update its status')
    perform_enqueued_jobs

    filename.reload
    expect(filename.count).to eq 3
  end

  it 'enables facets', js: true do
    c = create_metadata_collection

    login_as @owner
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Look & Feel')
    page.check('Enable metadata facets')
    expect(page).to have_content('Collection has been updated')
    page.click_link('Edit Facets')
    expect(page).to have_content('Metadata Facets')
    expect(page).to have_content('Configure metadata facets by reviewing the metadata in your collection and labelling fields to be displayed to transcribers.')
    expect(page).to have_content('filename')
    expect(page).to have_content('field_identifier_local')
  end

  it 'allows saving additional metadata' do
    c = create_metadata_collection

    login_as @owner
    visit edit_collection_path(@owner, c)
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
    c = create_metadata_collection

    login_as @owner
    visit edit_collection_path(@owner, c)
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
    c = create_metadata_collection

    login_as @owner
    visit edit_collection_path(@owner, c)
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
    c = create_metadata_collection

    login_as @owner
    visit edit_collection_path(@owner, c)
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
    c = create_metadata_collection

    logout
    @owner.update!(account_type: 'Individual Researcher')
    login_as @owner
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Look & Feel')
    expect(page).to have_field('Enable metadata facets', disabled: true)
    expect(page.find_link('Edit Facets')).to match_css('[disabled]')
    expect(page).to have_content('Not available for researcher accounts.')
  end

  it 'deletes a collection' do
    c = create_metadata_collection(title: collection_title)

    logout
    login_as @owner
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Danger Zone')
    expect(page).to have_content(collection_title)
    expect(page).to have_content('Please use caution')
    click_link 'Delete Collection'
    expect(page).not_to have_content(collection_title)
    expect(c.metadata_coverages).to be_empty
  end
end
