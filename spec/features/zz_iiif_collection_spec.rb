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
    else
      DatabaseCleaner.clean
    end
  end

  it 'queues an IIIF collection import', js: true do
    # Exercise the browser-to-job handoff; task behavior has its own specs.
    queued_imports = []
    allow(Process).to receive(:spawn).and_wrap_original do |original, *args, **options|
      if args.any? { |arg| arg.is_a?(String) && arg.start_with?('fromthepage:import_iiif_collection[') }
        queued_imports << args
        12_345
      else
        original.call(*args, **options)
      end
    end
    allow(Process).to receive(:detach).and_call_original
    allow(Process).to receive(:detach).with(12_345).and_return(nil)
    visit dashboard_owner_path
    VCR.use_cassette('iiif/cambridge_hebrew_mss', record: :none) do
      page.find('.tabs').click_link('Start A Project')
      page.find(:css, '#import-iiif-manifest').click
      page.fill_in 'at_id', with: at_id
      find_button('iiif_import').click
      expect(page).to have_content(at_id, wait: 20)
      expect(page).to have_content('Manifests')
      select('Create Collection', from: 'manifest_import')
      click_button('Import Checked Manifests')
      expect(page).to have_css('.flash_message', text: 'IIIF collection import is processing', wait: 20)
      imported = owner.collections.last
      expect(page).to have_current_path(collection_path(owner, imported))
      expect(page).to have_content('Works')
      expect(imported.title).to have_content('Library')
      expect(queued_imports.size).to eq(1)
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
