require 'spec_helper'

describe TranscriptionField::Lib::Utils do
  describe '.parse_fields' do
    let!(:owner) { create(:unique_user, :owner) }
    let!(:collection) { create(:collection, :field_based, owner_user_id: owner.id) }
    let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
    let!(:page) { create(:page, work: work) }
    let!(:spreadsheet_field) do
      create(
        :transcription_field, :as_transcription,
        collection: collection, label: 'Spreadsheet', input_type: 'spreadsheet'
      )
    end
    let!(:text_column) do
      create(
        :spreadsheet_column,
        transcription_field: spreadsheet_field,
        label: 'Text Column',
        input_type: 'text',
        position: 1
      )
    end

    it 'escapes parse-invalid XML-like spreadsheet cell content' do
      field_cells = {
        spreadsheet_field.id.to_s => {
          spreadsheet_field.label => [['<test>']].to_json
        }
      }

      parsed_page = described_class.parse_fields(page: page, field_cells: field_cells)

      expect(parsed_page.transcription_json[spreadsheet_field.id].first[text_column.id])
        .to eq('&lt;test&gt;')
      expect(parsed_page.source_text).to include('&lt;test&gt;')
    end

    it 'preserves parse-valid XML content in spreadsheet cells' do
      field_cells = {
        spreadsheet_field.id.to_s => {
          spreadsheet_field.label => [['<hi>ok</hi>']].to_json
        }
      }

      parsed_page = described_class.parse_fields(page: page, field_cells: field_cells)

      expect(parsed_page.transcription_json[spreadsheet_field.id].first[text_column.id])
        .to eq('<hi>ok</hi>')
      expect(parsed_page.source_text).to include('<hi>ok</hi>')
    end
  end
end
