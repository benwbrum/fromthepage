require 'spec_helper'

describe Work::Metadata::ExportCsv do
  before do
    Current.user = owner
  end

  let(:owner) { User.find_by(login: OWNER) }
  let(:user) { User.find_by(login: USER) }

  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:metadata_field_1) { create(:transcription_field, :as_metadata, collection: collection, label: 'Label 1') }
  let!(:metadata_field_2) { create(:transcription_field, :as_metadata, collection: collection, label: 'Label 2') }
  let!(:metadata_field_3) { create(:transcription_field, :as_metadata, collection: collection, label: 'Label 3') }

  let(:original_metadata) { [ { label: 'en', value: 'Original Metadata' } ].to_json }
  let(:metadata_description) do
    [
      { transcription_field_id: metadata_field_1.id, value: 'Value 1' },
      { transcription_field_id: metadata_field_2.id, value: [ 'Value 2', 'Value 3' ] }
    ].to_json
  end
  let!(:work_1) do
    create(:work, collection: collection, owner_user_id: owner.id, original_metadata: original_metadata,
                  metadata_description: metadata_description)
  end
  let!(:deed) { create(:deed, work: work_1, user: user, deed_type: DeedType::WORK_ADDED) }
  let!(:work_2) { create(:work, collection: collection, owner_user_id: owner.id) }

  let(:result) do
    described_class.new(collection: collection.reload, works: collection.works).call
  end

  let(:expected_headers) do
    [
      'FromThePage Title',
      '*Collection*',
      '*Document Sets*',
      '*Uploaded Filename*',
      '*FromThePage ID*',
      '*FromThePage Slug*',
      '*FromThePage URL*',
      'FromThePage Description',
      'Identifier',
      '*Originating Manifest ID*',
      '*Creation Date*',
      '*Total Pages*',
      '*Pages Transcribed*',
      '*Pages Corrected*',
      '*Pages Indexed*',
      '*Pages Translated*',
      '*Pages Needing Review*',
      '*Pages Marked Blank*',
      '*Contributors*',
      '*Contributors Name*',
      'en',
      '*Description Status*',
      '*Described By*',
      'Label 1',
      'Label 2',
      'Label 3'
    ]
  end

  it 'exports csv' do
    expect(result.success?).to be_truthy
    csv_string = result.csv_string
    csv = CSV.parse(csv_string, headers: true)

    expect(csv.headers).to eq(expected_headers)

    expect(csv.first['FromThePage Title']).to eq(work_1.title)
    expect(csv.first['*FromThePage Slug*']).to eq(work_1.slug)
    expect(csv.first['*Contributors*']).to include(user.login)
    expect(csv.first['*Contributors*']).to include(user.email)
    expect(csv.first['en']).to eq('Original Metadata')

    # Transcription fields
    expect(csv.first['Label 1']).to eq('Value 1')
    expect(csv.first['Label 2']).to eq('Value 2; Value 3')
    expect(csv.first['Label 3']).to eq('')
  end
end
