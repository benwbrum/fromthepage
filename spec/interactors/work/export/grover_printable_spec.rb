require 'spec_helper'

describe Work::Export::GroverPrintable do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, title: 'Special-Tags-Collection') }
  let!(:work) { create(:work, title: 'Special-Tags-Work', collection: collection, owner_user_id: owner.id) }

  let(:source_text) do
    File.read(Rails.root.join('test_data', 'transcripts', 'special_tags.txt'))
  end

  let(:tex_text) do
    File.read(Rails.root.join('test_data', 'transcripts', 'special_tags.tex.erb'))
  end

  let!(:page) do
    create(:page, title: 'Special Tags Page', work: work, source_text: source_text, xml_text: xml_text, search_text: 'Search text',
      status: :transcribed)
  end
  let!(:page) do
    page = create(:page, title: 'Special Tags Page', work: work, search_text: 'Search text', status: :transcribed)
    page.update!(source_text: source_text)

    page
  end
  let!(:deed) { create(:deed, deed_type: DeedType::WORK_ADDED, work: work, collection: collection, user: owner) }

  let(:time) { Time.now.utc }

  let(:result) do
    described_class.new(
      work: work,
      edition: 'text',
      include_metadata: true,
      include_contributors: true,
      include_notes: true,
      preserve_lb: false,
      time: time
    ).call
  end

  it 'generates successfully' do
    expect(result.success?).to be_truthy
    expect(result.file).to be_present
  end
end
