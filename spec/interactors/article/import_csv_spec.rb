require 'spec_helper'

describe Article::ImportCsv do
  before do
    Current.user = owner
  end

  let(:owner) { create(:unique_user, :owner) }
  let(:user) { create(:unique_user) }

  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }

  let(:original_filename) { 'subject_upload.csv' }
  let(:file_path) { Rails.root.join('test_data/imports/subject_upload.csv') }
  let(:file_type) { 'text/csv' }
  let(:file) { Rack::Test::UploadedFile.new(file_path, file_type) }
  let(:timestamp) { Time.now }
  let(:provenance) { "#{original_filename} (uploaded #{timestamp} UTC)" }

  let(:result) do
    described_class.new(
      file: file.tempfile,
      original_filename: original_filename,
      collection: collection.reload,
      timestamp: timestamp
    ).call
  end

  it 'imports csv' do
    expect(collection.articles.count).to eq(0)
    expect(collection.categories.count).to eq(2)

    expect(result.success?).to be_truthy

    expect(collection.articles).to match_array([
      have_attributes(title: 'Sally Joseph Carr Brumfield', uri: 'P001001', source_text: 'Daughter of Rufus Bascom Carr and Fannie Edmonia Hobson', sex: 'M', provenance: provenance),
      have_attributes(title: 'Renan, Virginia', uri: 'https://www.wikidata.org/wiki/Q7312529', source_text: '', sex: 'F', provenance: provenance),
      have_attributes(title: 'stripping tobacco', uri: nil, source_text: '', sex: nil, provenance: provenance)
    ])
    expect(collection.categories).to match_array([
      have_attributes(title: 'People'),
      have_attributes(title: 'Places'),
      have_attributes(title: 'Agricultural Activities')
    ])
  end

  context 'when missing headers' do
    let(:original_filename) { 'wrong_subject_upload.csv' }
    let(:file_path) { Rails.root.join('test_data/imports/wrong_subject_upload.csv') }

    it 'fails csv import' do
      expect(result.success?).to be_falsey
    end
  end
end
