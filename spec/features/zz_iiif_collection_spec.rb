require 'spec_helper'

RSpec.describe 'uploads data for collections', order: :defined do
  let(:owner) { create(:unique_user, :owner) }
  let(:at_id) { 'https://iiif.durham.ac.uk/manifests/trifle/collection/32150/t2c0g354f205' }

  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
    login_as(owner, scope: :user)
  end

  after do |example|
    if example.metadata[:js]
      Collection.where(owner_user_id: owner.id).find_each(&:destroy!) if owner&.persisted?
      owner.destroy! if owner&.persisted?
    else
      DatabaseCleaner.clean
    end
  end

  it 'imports an IIIF collection', js: true do
    visit dashboard_owner_path
    VCR.use_cassette('iiif/cambridge_hebrew_mss', record: :none) do
      page.find('.tabs').click_link('Start A Project')
      page.find(:css, '#import-iiif-manifest').click
      page.fill_in 'at_id', with: at_id
      find_button('iiif_import').click
      expect(page).to have_content(at_id)
      expect(page).to have_content('Manifests')
      select('Create Collection', from: 'manifest_import')
      click_button('Import Checked Manifests')
      expect(page.find('.flash_message')).to have_content('IIIF collection import is processing')
      sleep(55)
      expect(page).to have_content('Works')
      expect(owner.collections.last.title).to have_content('Library')
      expect(owner.collections.last.works.count).not_to be_nil
    end
  end

  it "checks to allow '.' in IIIF domain URL parameter" do
    visit 'iiif/contributions/ac.uk'
    expect(page).to have_content('resources')
    visit '/iiif/contributions/ac.uk/2018-01-01'
    expect(page).to have_content('ac.uk')
    visit '/iiif/contributions/ac.uk/2018-01-01/2019-12-31'
    expect(page).to have_content('ac.uk')
  end

  it 'cleans up the logfile' do
    collection = create(:collection, owner_user_id: owner.id, works: [])
    log_file = Rails.root.join('public', 'imports', "#{collection.id}_iiif.log")
    FileUtils.mkdir_p(log_file.dirname)
    File.write(log_file, 'test log')

    File.delete(log_file)

    expect(File.exist?(log_file)).to be false
  end
end
