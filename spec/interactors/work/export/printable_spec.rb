require 'spec_helper'

describe Work::Export::Printable do
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
    page = create(:page, title: 'Special Tags Page', work: work, search_text: 'Search text', status: :transcribed)
    page.update!(source_text: source_text)

    page
  end
  let!(:deed) { create(:deed, deed_type: DeedType::WORK_ADDED, work: work, collection: collection, user: owner) }

  let(:format) { 'pdf' }
  let(:time) { Time.now.utc }

  let!(:expected_tex_string) do
    renderer = ERB.new(tex_text)
    renderer.result_with_hash(
      made_on: time,
      created_on: work.created_on.to_s,
      identifier: Work::Export::Lib::Utils.latex_escape(
        work.merge_metadata.select { |hash| hash["label"] == "Identifier" }.first["value"]
      ),
      owner_display_name: Work::Export::Lib::Utils.latex_escape(owner.real_name || owner.display_name),
      last_article_id: page.articles.last.id
    )
  end

  let(:result) do
    described_class.new(
      work: work,
      format: format,
      edition: 'text',
      include_metadata: true,
      include_contributors: true,
      include_notes: true,
      preserve_lb: false,
      time: time
    ).call
  end

  context 'when pdf' do
    it 'creates base tex' do
      expect(result.success?).to be_truthy
      expect(result.tex_string.rstrip).to eq(expected_tex_string.rstrip)
      expect(File.exist?(result.file)).to be_truthy
    end
  end

  context 'when doc' do
    let(:format) { 'doc' }
    it 'creates base tex' do
      expect(result.success?).to be_truthy
      expect(result.tex_string.rstrip).to eq(expected_tex_string.rstrip)
      expect(File.exist?(result.file)).to be_truthy
    end
  end

  context 'when html' do
    let(:format) { 'html' }
    it 'creates base tex' do
      expect(result.success?).to be_truthy
      expect(result.tex_string.rstrip).to eq(expected_tex_string.rstrip)
      expect(File.exist?(result.file)).to be_truthy
    end
  end
end
