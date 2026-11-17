require 'spec_helper'

describe Work::ImportAnnotationText do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:manifest_url) { 'https://iiif.archive.org/iiif/mcht_c55_massey_26/manifest.json' }
  let(:manifest_json) { File.read(Rails.root.join('test_data/iiif/internet_archive/mcht_c55_massey_26_manifest.json')) }
  let(:annotation_json) { File.read(Rails.root.join('test_data/iiif/internet_archive/journalofexpedit00ford_annotations_6.json')) }
  let(:annotation_urls) do
    (1..2).map { |n| "https://iiif.archive.org/iiif/3/annotations/mcht_c55_massey_26/mcht_c55_massey_26_djvu.xml/#{n}.json" }
  end
  let(:work) do
    Current.user = owner
    ScManifest.manifest_for_v3_hash(manifest_json).convert_with_collection(owner, collection)
  end
  let(:first_page) { work.pages.first }
  let(:second_page) { work.pages.second }

  before do
    allow(IiifHttp).to receive(:sleep)
    stub_request(:get, manifest_url).to_return(status: 200, body: manifest_json)
    annotation_urls.each { |url| stub_request(:get, url).to_return(status: 200, body: annotation_json) }
  end

  after do
    Current.user = nil
  end

  it 'turns word annotations into lines of page text' do
    result = described_class.new(work: work, user: owner).call

    expect(result.success?).to be(true)
    expect(result.imported_page_ids).to eq([first_page.id, second_page.id])
    expect(first_page.reload.source_text.lines.first(3).map(&:chomp)).to eq(
      ['[David Ford was a native of Morristown, N. J., and having in early life',
       'lost both parents, he spent his childhood with his paternal grandfather,',
       'Jacob Ford. The death of the latter occurred']
    )
    expect(first_page.xml_text).to include('Morristown')
    expect(first_page.page_versions.last.user).to eq(owner)
  end

  it 'skips pages that already have text' do
    first_page.update!(source_text: 'Transcribed by hand')

    result = described_class.new(work: work, user: owner).call

    expect(result.imported_page_ids).to eq([second_page.id])
    expect(first_page.reload.source_text).to eq('Transcribed by hand')
    expect(a_request(:get, annotation_urls.first)).not_to have_been_made
  end

  it 'imports the remaining pages and fails when an annotation page cannot be fetched' do
    stub_request(:get, annotation_urls.first).to_return(status: 500)

    result = described_class.new(work: work, user: owner).call

    expect(result.success?).to be(false)
    expect(result.full_errors.message).to eq("Could not import annotation text for pages #{first_page.id}")
    expect(first_page.reload.source_text).to be_blank
    expect(second_page.reload.source_text).to include('Morristown')
  end

  it 'reads embedded annotation pages and HTML bodies without fetching them' do
    manifest = JSON.parse(manifest_json)
    manifest['items'].first['annotations'] = [{
      'type' => 'AnnotationPage',
      'items' => [
        { 'type' => 'Annotation', 'motivation' => 'supplementing',
          'body' => { 'type' => 'TextualBody', 'format' => 'text/html', 'value' => 'Dear Barbara,<br>All is well & good' } },
        { 'type' => 'Annotation', 'motivation' => 'commenting',
          'body' => [{ 'type' => 'TextualBody', 'value' => 'Love, Harry' }, { 'type' => 'Image' }] },
        { 'type' => 'Annotation', 'motivation' => 'painting',
          'body' => { 'type' => 'TextualBody', 'value' => 'not text' } }
      ]
    }]
    stub_request(:get, manifest_url).to_return(status: 200, body: manifest.to_json)

    described_class.new(work: work, user: owner).call

    expect(first_page.reload.source_text).to eq("Dear Barbara,\nAll is well &amp; good\nLove, Harry")
    expect(a_request(:get, annotation_urls.first)).not_to have_been_made
  end

  it 'refuses users who cannot edit the work' do
    result = described_class.new(work: work, user: create(:unique_user)).call

    expect(result.success?).to be(false)
    expect(result.full_errors.message).to eq('User may not edit this work')
    expect(a_request(:get, manifest_url)).not_to have_been_made
  end
end
