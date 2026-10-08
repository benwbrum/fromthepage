require 'spec_helper'
require 'stringio'
require 'contentdm_import_cleanup'

RSpec.describe ContentdmImportCleanup do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let(:page) { create(:page, work: work) }
  let(:audit) { StringIO.new }
  let(:cleaner) { described_class.new(apply: true, repair_deeds: true, audit: audit) }
  let(:timestamp) { page.created_on }
  let!(:manifest) { ScManifest.create!(work: work, at_id: 'https://cdm123.contentdm.oclc.org/iiif/info/test/1/manifest.json') }
  let!(:duplicate) do
    initial = page.page_versions.first
    initial.update_columns(created_on: timestamp)
    PageVersion.create!(initial.attributes.except('id').merge(page_version: 1, created_on: timestamp + 10.seconds)).tap do |version|
      page.update_columns(page_version_id: version.id)
    end
  end

  before { Current.user = owner }
  after { Current.reset }

  it 'dry runs without deleting records' do
    result = described_class.new(audit: audit).repair(page)
    expect(result).to eq(:candidate)
    expect(duplicate.reload).to be_present
    expect(JSON.parse(audit.string)['deleted_version']['id']).to eq(duplicate.id)
  end

  it 'repairs an untouched page pointer and is idempotent' do
    expect(cleaner.repair(page)).to eq(:repaired)
    expect(page.reload.page_version_id).to eq(page.page_versions.first.id)
    expect(page.page_versions.count).to eq(1)
    expect(cleaner.repair(page)).to eq(:no_duplicate)
  end

  def transcribe
    page.update!(source_text: 'First human text', status: :transcribed)
    human = page.page_versions.reorder(:id).last
    human.update_columns(created_on: timestamp + 2.minutes)
    deed = Deed.create!(page: page, work: work, collection: collection, user: owner,
                        deed_type: DeedType::PAGE_EDIT, created_at: human.created_on + 1.second)
    [human, deed]
  end

  it 'renumbers history and restores credit without changing content or activity timestamps' do
    human, deed = transcribe
    deed_time = deed.updated_at
    version_counter = work.reload.transcription_version
    recent_activity = collection.reload.most_recent_deed_created_at
    expect(cleaner.repair(page)).to eq(:repaired)
    expect(human.reload.page_version).to eq(1)
    expect(page.reload).to have_attributes(source_text: 'First human text', status: 'transcribed', page_version_id: human.id)
    expect(deed.reload).to have_attributes(deed_type: DeedType::PAGE_TRANSCRIPTION, updated_at: deed_time)
    expect(deed.prerender).to be_present
    expect(collection.reload.most_recent_deed_created_at).to eq(recent_activity)
    expect(work.reload.transcription_version).to eq(version_counter)
  end

  it 'leaves ambiguous deeds as edits' do
    human, deed = transcribe
    Deed.create!(page: page, work: work, collection: collection, user: owner,
                 deed_type: DeedType::PAGE_EDIT, created_at: human.created_on + 2.seconds)
    expect(cleaner.repair(page)).to eq(:repaired)
    expect(deed.reload.deed_type).to eq(DeedType::PAGE_EDIT)
  end

  it 'allows version cleanup without changing deeds' do
    _human, deed = transcribe
    cleaner = described_class.new(apply: true, audit: audit)
    expect(cleaner.repair(page)).to eq(:repaired)
    expect(deed.reload.deed_type).to eq(DeedType::PAGE_EDIT)
  end

  it 'skips pages with activity during import' do
    Deed.create!(page: page, work: work, collection: collection, user: owner,
                 deed_type: DeedType::PAGE_EDIT, created_at: timestamp + 5.seconds)
    expect(cleaner.repair(page)).to eq(:early_activity)
  end

  it 'does not write when the audit fails' do
    allow(audit).to receive(:puts).and_raise(IOError)
    expect { cleaner.repair(page) }.to raise_error(IOError)
    expect(duplicate.reload).to be_present
  end

  it 'skips unexpected current-version pointers' do
    page.update_columns(page_version_id: nil)
    expect(cleaner.repair(page)).to eq(:unexpected_pointer)
  end

  it 'skips OCR imports' do
    work.update!(ocr_correction: true)
    expect(cleaner.repair(page)).to eq(:ocr)
    expect(duplicate.reload).to be_present
  end

  it 'preserves nonblank imported text' do
    duplicate.update_columns(transcription: 'Imported OCR')
    expect(cleaner.repair(page)).to eq(:content_present)
  end

  it 'preserves flagged snapshots' do
    Flag.create!(page_version: duplicate)
    expect(cleaner.repair(page)).to eq(:flagged)
  end

  it 'skips delayed imports rather than assuming an owner edit is automated' do
    duplicate.update_columns(created_on: timestamp + 1.hour)
    expect(cleaner.repair(page)).to eq(:outside_import_window)
  end
end
