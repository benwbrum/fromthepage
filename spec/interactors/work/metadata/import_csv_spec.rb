require 'spec_helper'
require 'csv'

describe Work::Metadata::ImportCsv do
  before do
    Current.user = owner
  end

  let(:owner) { User.find_by(login: OWNER) }
  let(:user) { User.find_by(login: USER) }

  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work_1) { create(:work, collection: collection, owner_user_id: owner.id) }
  let(:uploaded_filename) { "uploaded_filename_#{Time.current.to_i}" }
  let!(:work_2) do
    create(
      :work,
      collection: collection,
      owner_user_id: owner.id,
      title: 'Unchanged title',
      description: 'Unchanged description',
      identifier: 'unchanged_identifier', uploaded_filename: uploaded_filename,
      original_metadata: [ { label: 'Unchanged', value: 'Metadata' } ].to_json,
      author: 'Unchanged author',
      recipient: 'Nulled recipient'
    )
  end

  let!(:collection_2) { create(:collection, owner_user_id: owner.id) }
  let(:work_3) { collection_2.works.first }

  let(:headers) do
    [
      'FromThePage Title',
      '*Collection*',
      '*Uploaded Filename*',
      '*FromThePage ID*',
      'FromThePage Description',
      'Identifier',
      # Additional metadata headers
      'Author',
      'Recipient',
      # Metadata fields
      'Label 1',
      'Label 2'
    ]
  end

  let(:work_1_data) do
    # Case Work 1
    # - FromThePage ID present
    # - FromThePage Title present
    # - FromThePage Description present
    # - Identifier present
    # - Author present
    # - Recipient present
    # - Metadata present
    [
      'New title',
      work_1.collection.title,
      '',
      work_1.id,
      'New description',
      'new_identifier',
      'New author',
      'New recipient',
      'Value 1',
      'Value 2'
    ]
  end

  let(:work_2_data) do
    # Case Work 2
    # - Uploaded Filename present
    # - FromThePage Title blank
    # - FromThePage Description blank
    # - Identifier blank
    # - Author blank
    # - Recipient set to ' ' to nullify column
    # - Metadata blank
    [
      '',
      work_2.collection.title,
      uploaded_filename,
      '',
      '',
      '',
      '',
      ' ',
      '',
      ''
    ]
  end

  let(:work_3_data) do
    # Case Work 3
    # - Work from a different collection
    # - FromThePage ID present
    [
      work_3.title,
      work_3.collection.title,
      '',
      work_3.id,
      '',
      '',
      '',
      '',
      '',
      ''
    ]
  end

  let(:work_4_data) do
    # Case Work 4
    # - Non-existing work id
    [
      'Non-existing work id',
      '',
      '',
      'NON-EXISTING-WORK-ID',
      '',
      '',
      '',
      '',
      '',
      ''
    ]
  end

  let(:work_5_data) do
    # Case Work 5
    # - Non-existing work filename
    [
      'Non-existing work filename',
      '',
      'NON-EXISTING-FILENAME',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ]
  end

  let(:work_6_data) do
    # Case Work 5
    # - Missing ID and filename, so nothing to identify work
    [
      'Missing ID and Filename',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ]
  end

  let(:metadata_file) do
    csv_data = CSV.generate(headers: true) do |csv|
      csv << headers
      [ work_1_data, work_2_data, work_3_data, work_4_data, work_5_data, work_6_data ].each do |work_data|
        csv << work_data
      end
    end
    temp_file = Tempfile.new([ 'metadata', '.csv' ])
    temp_file.write(csv_data)
    temp_file.rewind

    temp_file
  end

  let(:result) do
    described_class.new(metadata_file: metadata_file, collection: collection.reload).call
  end

  it 'imports csv' do
    expect(result.success?).to be_truthy
    expect(result.rowset_errors).to include(
      # Case work 3, different collection
      {
        error: I18n.t('metadata.import_csv.errors.not_in_collection', work_id: work_3.id, collection_title: collection.title),
        work_id: work_3.id.to_s,
        title: work_3.title
      },
      # Case work 4, non-existing work id
      {
        error: I18n.t('metadata.import_csv.errors.not_existing_work_id', work_id: 'NON-EXISTING-WORK-ID'),
        work_id: 'NON-EXISTING-WORK-ID',
        title: 'Non-existing work id'
      },
      # Case work 5, non-existing work filename
      {
        error: I18n.t('metadata.import_csv.errors.not_existing_work', work_filename: 'NON-EXISTING-FILENAME')
      },
      # Case work 6, no id or filename
      {
        error: I18n.t('metadata.import_csv.errors.filename_blank')
      }
    )
    expect(work_1.reload).to have_attributes(
      title: 'New title',
      description: 'New description',
      identifier: 'new_identifier',
      original_metadata: [ { label: 'Label 1', value: 'Value 1' }, { label: 'Label 2', value: 'Value 2' } ].to_json,
      author: 'New author',
      recipient: 'New recipient'
    )
    expect(work_2.reload).to have_attributes(
      title: 'Unchanged title',
      description: 'Unchanged description',
      identifier: 'unchanged_identifier',
      original_metadata: [ { label: 'Unchanged', value: 'Metadata' } ].to_json,
      author: 'Unchanged author',
      recipient: nil
    )
  end
end
