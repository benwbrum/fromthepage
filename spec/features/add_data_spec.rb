require 'spec_helper'

RSpec.describe 'uploads data for collections', order: :defined do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:empty_work_title) { "This is an empty work #{SecureRandom.hex(4)}" }

  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
    login_as(owner, scope: :user)
  end

  after do |example|
    if example.metadata[:js]
      Collection.where(owner_user_id: owner.id).find_each(&:destroy!) if owner&.persisted?
    else
      DatabaseCleaner.clean
    end
  end

  it 'sets slugs' do
    collection = create_collection_with_works
    work = collection.works.first

    collection.save!
    work.save!
    owner.save!

    expect(collection.slug).to be_present
    expect(work.slug).to be_present
    expect(owner.slug).to be_present
  end

  it 'starts a new project from tab', js: true do
    collection

    visit dashboard_owner_path
    page.find('.tabs').click_link('Start A Project')
    page.find(:css, '#document-upload').click

    select2_select(id: 'document_upload_collection_id', value: collection.title)

    attach_file(
      'document_upload_file',
      Rails.root.join('test_data/uploads/test.pdf'),
      make_visible: true
    )
    sleep 2
    click_button('Upload File')
    expect(page).to have_content('Document has been uploaded', wait: 30)
    title = find('h1').text
    expect(title).to eq collection.title
    wait_for_upload_processing
    sleep(10)
  end

  it 'starts an ocr project', js: true do
    collection

    visit dashboard_owner_path
    page.find('.tabs').click_link('Start A Project')
    page.find(:css, '#document-upload').click

    select2_select(id: 'document_upload_collection_id', value: collection.title)

    attach_file(
      'document_upload_file',
      Rails.root.join('test_data/uploads/ocr.pdf'),
      make_visible: true
    )
    sleep 2
    find('input[name="document_upload[ocr]"]').check
    click_button('Upload File')

    expect(page).to have_content('Document has been uploaded', wait: 30)
    title = find('h1').text
    expect(title).to eq collection.title
    wait_for_upload_processing
    uploaded_work = collection.works.reload.last
    expect(uploaded_work.ocr_correction).to eq true
    expect(uploaded_work.pages.first.source_text).to match 'dagegen'
  end

  it 'imports IIIF manifests' do
    collection

    VCR.use_cassette('iiif/imports_iiif_manifests', record: :none) do
      visit dashboard_owner_path
      page.find('.tabs').click_link('Start A Project')
      find('#at_id', visible: false)
        .set('https://iiif.io/api/cookbook/recipe/0001-mvm-image/manifest.json')
      find('#iiif_import', visible: false).click
      expect(page).to have_content('Metadata')
      expect(page).to have_content('Manifest')
      select(collection.title, from: 'sc_manifest_collection_id')
      click_button('Import Manifest')
      expect(page).to have_content(collection.title)
      visit dashboard_owner_path
      works_count = collection.works.reload.count
      page.find('.tabs').click_link('Start A Project')
      find('#at_id', visible: false)
        .set('https://iiif.io/api/cookbook/recipe/0009-book-1/manifest.json')
      find('#iiif_import', visible: false).click
      expect(page).to have_content('Metadata')
      expect(page).to have_content('Manifest')
      select(collection.title, from: 'sc_manifest_collection_id')
      click_button('Import')
      expect(page).to have_content(collection.title)
      expect(collection.works.reload.last.title.length).to be < 255
      expect(collection.works.reload.count).to be >= works_count
    end
  end

  it 'creates an empty work', js: true do
    collection

    visit dashboard_owner_path
    page.find('.tabs').click_link('Start A Project')
    page.find(:css, '#create-empty-work').click
    select2_select(id: 'work_collection_id', value: collection.title)
    fill_in 'work_title', with: empty_work_title
    fill_in 'work_description', with: 'This work contains no pages.'
    click_button('Create Work')
    expect(page).to have_content('Here you see the list of all pages in the work.')
    expect(Work.find_by(title: empty_work_title, collection: collection)).not_to be nil
  end

  it 'adds pages to an empty work' do
    empty_work = create(:work,
                        title: empty_work_title,
                        owner: owner,
                        owner_user_id: owner.id,
                        collection: collection)

    visit dashboard_owner_path
    page.find('.maincol').find('a', text: collection.title).click
    page.find('.maincol').find('a', text: empty_work.title).click
    page.find('.tabs').click_link('Pages')
    page.find('a', text: 'Add New Page').click
    attach_file(
      'page_image',
      Rails.root.join('test_data/uploads/JWGravesAmnestyPage1.jpg'),
      make_visible: true
    )
    click_button('Save & Add Next Page')
    expect(page).to have_content('Page created successfully')
    expect(empty_work.pages.reload).not_to be_empty
    expect(page).to have_content(empty_work.pages.first.title)
    click_link('Add New Page')
    attach_file(
      'page_image',
      Rails.root.join('test_data/uploads/JWGravesAmnestyPage2.jpg'),
      make_visible: true
    )
    click_button('Save & New Work')
    expect(empty_work.pages.reload.count).to eq 2
    expect(empty_work.reload.work_statistic[:total_pages]).to eq 2
    expect(page).to have_content('Create Empty Work')
  end

  it 'adds new document sets', js: true do
    set_collection = create_collection_with_works(supports_document_sets: false)

    visit dashboard_owner_path
    doc_set_count = owner.document_sets.count
    page.find('.maincol').find('a', text: set_collection.title).click
    page.find('.tabs').click_link('Settings')
    sleep 1
    page.find('.side-tabs').click_link('Look & Feel')
    page.check('Enable document sets')
    page.click_link('Edit Sets')
    expect(page).to have_content('Create a Document Set')
    click_link('Create a Document Set')
    expect(page).to have_selector('form#new_document_set')
    page.fill_in 'document_set_title', with: 'Test Document Set 1'
    click_button('Create Document Set')
    expect(page).to have_content('Document set has been created')
    expect(owner.document_sets.last.is_public).to be true
    expect(page.current_path).to eq collection_settings_path(owner, owner.document_sets.last)
    expect(page).to have_content('Manage Works')
    expect(page.find('h1')).to have_content('Test Document Set 1')
    owner.document_sets.last.update!(work_ids: [set_collection.works.reload.second.id])
    expect(owner.document_sets.count).to eq(doc_set_count + 1)

    visit document_sets_path(collection_id: set_collection)
    doc_set_count = owner.document_sets.count
    page.find('.button', text: 'Create a Document Set').click
    page.fill_in 'document_set_title', with: 'Test Document Set 2'
    find('#select2-document_set_visibility-container').click
    find('.select2-results__option', text: 'Private').click
    page.find_button('Create Document Set').click
    sleep(3)
    expect(page.current_path).to eq collection_settings_path(owner, owner.document_sets.last)
    expect(page).to have_content('Manage Works')
    expect(page.find('h1')).to have_content('Test Document Set 2')
    expect(owner.document_sets.last.is_public).to be false
    expect(owner.document_sets.count).to eq(doc_set_count + 1)
  end

  it 'adds works to document sets' do
    set_collection = create_collection_with_works(supports_document_sets: true)
    document_sets = create_list(:document_set, 2,
                                :public,
                                collection: set_collection,
                                owner: owner,
                                owner_user_id: owner.id)

    visit dashboard_owner_path
    page.find('.maincol').find('a', text: set_collection.title).click
    page.find('.tabs').click_link('Sets')
    expect(page).to have_content("Document Sets for #{set_collection.title}")
    page.check("work_assignment_#{set_collection.works.first.slug}_#{document_sets.first.slug}")
    page.check("work_assignment_#{set_collection.works.last.slug}_#{document_sets.last.slug}")
    page.find_button('Save').click
  end

  def create_collection_with_works(supports_document_sets: true)
    create(:collection,
           owner_user_id: owner.id,
           works: [],
           supports_document_sets: supports_document_sets).tap do |created_collection|
      2.times do
        work = create(:work, owner: owner, owner_user_id: owner.id, collection: created_collection)
        create(:page, work: work, position: 1)
      end
      created_collection.works.reset
    end
  end
end
