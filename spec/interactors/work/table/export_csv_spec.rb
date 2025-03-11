require 'spec_helper'

describe Work::Table::ExportCsv do
  include Rails.application.routes.url_helpers

  before do
    User.current_user = owner
  end

  let(:owner) { User.find_by(login: OWNER) }
  let(:user) { User.find_by(login: USER) }

  let(:collection) { create(:collection, owner_user_id: owner.id, works: [], field_based: true) }
  let!(:metadata_field) { create(:transcription_field, :as_metadata, collection: collection, label: 'Metadata Field') }
  let!(:text_field) do
    create(:transcription_field, :as_transcription, collection: collection, label: 'Text Field', input_type: 'text')
  end
  let!(:spreadsheet_field) do
    create(:transcription_field, :as_transcription, collection: collection, label: 'Spreadsheet Field',
                                                    input_type: 'spreadsheet')
  end
  let!(:spreadsheet_column) do
    create(:spreadsheet_column, transcription_field: spreadsheet_field, label: 'Text Column', input_type: 'text')
  end
  let(:metadata) do
    {
      'Metadata Field' => 'Value 1'
    }
  end
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id, identifier: 'identifier') }
  let(:transcription_json) do
    tj = {}
    tj[text_field.id.to_s] = 'Text Field Value'

    tj[spreadsheet_field.id.to_s] = [0, 1].map do |i|
      sf = {}
      sf[spreadsheet_column.id.to_s] = "Text Column Value #{i}"

      sf
    end

    tj
  end
  let!(:page) do
    create(:page, :transcribed, work: work, transcription_json: transcription_json, position: 1,
                                metadata: metadata)
  end
  let!(:note) do
    create(:note, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: owner.id, body: 'Note')
  end

  let!(:deed) { create(:deed, work: work, page: page, user: user, deed_type: DeedType::PAGE_TRANSCRIPTION) }

  let(:result) do
    described_class.new(collection: collection.reload, works: collection.works).call
  end

  let(:expected_headers) do
    [
      'Work Title',
      'Work Identifier',
      'FromThePage Identifier',
      'Page Title',
      'Page Position',
      'Page URL',
      'Page Contributors',
      'Page Notes',
      'Page Status',
      'Metadata Field',
      'Text Field',
      'Spreadsheet Field Text Column'
    ]
  end

  it 'exports csv' do
    expect(result.success?).to be_truthy
    csv_string = result.csv_string
    csv = CSV.parse(csv_string, headers: true, encoding: 'UTF-8')

    expect(csv.headers).to eq(expected_headers)

    [0, 1].each do |i|
      expect(csv[i]['Work Title']).to eq(work.title)
      expect(csv[i]['Work Identifier']).to eq(work.identifier)
      expect(csv[i]['FromThePage Identifier']).to eq(work.id.to_s)
      expect(csv[i]['Page Title']).to eq(page.title)
      expect(csv[i]['Page Position']).to eq(page.position.to_s)
      expect(csv[i]['Page URL']).to eq(collection_display_page_url(owner, collection, work, page))
      expect(csv[i]['Page Contributors']).to eq("#{user.display_name}<#{user.email}>")
      expect(csv[i]['Page Notes']).to eq("[#{owner.display_name}<#{owner.email}>]: Note")
      expect(csv[i]['Page Status']).to eq('Complete')

      # Metadata headers
      expect(csv[i]['Metadata Field']).to eq('Value 1')

      # Transcription fields
      expect(csv[i]['Text Field']).to eq('Text Field Value')
      expect(csv[i]['Spreadsheet Field Text Column']).to eq("Text Column Value #{i}")
    end
  end
end
