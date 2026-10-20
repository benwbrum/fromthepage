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

  let(:original_metadata) { [{ label: 'en', value: 'Original Metadata' }].to_json }
  let(:metadata_description) do
    [
      { transcription_field_id: metadata_field_1.id, value: 'Value 1' },
      { transcription_field_id: metadata_field_2.id, value: ['Value 2', 'Value 3'] }
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

  context 'with AI metadata drafts' do
    let(:draft_metadata) do
      {
        metadata_field_2.id.to_s => ['Draft value 2', 'Draft value 3'],
        metadata_field_1.id.to_s => 'Draft value 1'
      }
    end
    let!(:draft) do
      create(:ai_work_metadata, work_id: work_2.id, status: :finished, metadata_json: draft_metadata)
    end
    let(:csv) { CSV.parse(result.csv_string, headers: true) }
    let(:draft_row) { csv.find { |candidate| candidate['*FromThePage ID*'] == work_2.id.to_s } }

    it 'exports drafts without requiring reviewed or original metadata' do
      expect(result.success?).to be_truthy
      expect(csv.headers).to eq(expected_headers + ['Label 1 (AI Draft)', 'Label 2 (AI Draft)', 'Label 3 (AI Draft)'])

      expect(draft_row['en']).to eq('')
      expect(draft_row['*Description Status*']).to eq('')
      expect(draft_row['*Described By*']).to eq('')
      expect(draft_row['Label 1']).to eq('')
      expect(draft_row['Label 1 (AI Draft)']).to eq('Draft value 1')
      expect(draft_row['Label 2 (AI Draft)']).to eq('Draft value 2; Draft value 3')
      expect(draft_row['Label 3 (AI Draft)']).to eq('')
      expect(CSV.parse(result.csv_string).map(&:size).uniq).to eq([csv.headers.size])
      expect(work_2.reload.metadata_description).to be_nil
    end

    it 'keeps reviewed values separate and leaves missing drafts blank' do
      expect(csv.first['Label 1']).to eq('Value 1')
      expect(csv.first['Label 2']).to eq('Value 2; Value 3')
      expect(csv.first['Label 1 (AI Draft)']).to eq('')
      expect(csv.first['Label 2 (AI Draft)']).to eq('')

      create(:ai_work_metadata, work_id: work_1.id, status: :finished, metadata_json: draft_metadata)
      updated_result = described_class.new(collection: collection, works: collection.works).call
      row = CSV.parse(updated_result.csv_string, headers: true).first
      expect(row['Label 1']).to eq('Value 1')
      expect(row['Label 1 (AI Draft)']).to eq('Draft value 1')
    end

    it 'uses the latest finished draft across engines and ignores unfinished attempts' do
      draft.update!(created_at: 2.days.ago)
      create(:ai_work_metadata, work_id: work_2.id, status: :finished, model: 'claude-sonnet-4-6',
                               created_at: 1.day.ago, metadata_json: { metadata_field_1.id.to_s => 'Latest draft' })
      [:new, :processing, :error].each do |status|
        create(:ai_work_metadata, work_id: work_2.id, status: status,
                                 metadata_json: { metadata_field_1.id.to_s => 'Unfinished draft' })
      end

      expect(draft_row['Label 1 (AI Draft)']).to eq('Latest draft')
      expect(draft_row['Label 2 (AI Draft)']).to eq('')
    end

    it 'leaves draft columns blank when there is no finished draft' do
      draft.update!(status: :processing)

      expect(csv.headers).to include('Label 1 (AI Draft)')
      expect(draft_row['Label 1 (AI Draft)']).to eq('')
    end

    it 'handles a finished draft without metadata' do
      draft.update!(metadata_json: nil)

      expect(result.success?).to be_truthy
      expect(draft_row['Label 1 (AI Draft)']).to eq('')
    end
  end
end
