require 'spec_helper'

describe Page, 'field-based AI plaintext' do
  let!(:owner)      { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, :field_based, owner_user_id: owner.id) }
  let!(:work)       { create(:work, collection: collection) }
  let!(:page)       { create(:page, work: work) }
  let!(:text_field) do
    create(:transcription_field, :text_field,
           label: 'Name', collection: collection, position: 1, line_number: 1)
  end
  let!(:select_field) do
    create(:transcription_field, :select_field,
           label: 'County', options: 'Beaver;Box Elder',
           collection: collection, position: 2, line_number: 2)
  end

  let(:transcription_json) do
    { text_field.id.to_s => 'John Smith', select_field.id.to_s => 'Beaver' }
  end

  describe '#ai_plaintext' do
    context 'with a field-based AI transcription (transcription_json set, source_text nil)' do
      let!(:ai_transcription) do
        create(:ai_transcription, page_id: page.id, source_text: nil,
               status: :finished, transcription_json: transcription_json)
      end

      it 'returns "Label: value" formatted plaintext' do
        result = page.reload.ai_plaintext
        expect(result).to include('Name: John Smith')
        expect(result).to include('County: Beaver')
      end
    end

    context 'with a standard (non-field-based) AI transcription' do
      let!(:ai_transcription) do
        create(:ai_transcription, page_id: page.id,
               source_text: 'This is transcribed text', status: :finished)
      end

      it 'returns source_text unchanged' do
        expect(page.reload.ai_plaintext).to eq('This is transcribed text')
      end
    end
  end

  describe '#has_ai_plaintext?' do
    context 'when transcription_json is populated and source_text is nil' do
      let!(:ai_transcription) do
        create(:ai_transcription, page_id: page.id, source_text: nil,
               status: :finished, transcription_json: transcription_json)
      end

      it 'returns true' do
        expect(page.reload.has_ai_plaintext?).to be true
      end
    end

    context 'when both source_text and transcription_json are blank' do
      let!(:ai_transcription) do
        create(:ai_transcription, page_id: page.id, source_text: nil,
               status: :finished)
      end

      it 'returns false' do
        expect(page.reload.has_ai_plaintext?).to be false
      end
    end
  end

  describe '#field_transcription_json_to_plaintext' do
    it 'formats each field as "Label: value"' do
      result = page.send(:field_transcription_json_to_plaintext, transcription_json)
      expect(result).to include('Name: John Smith')
      expect(result).to include('County: Beaver')
    end

    it 'skips fields with nil values' do
      json = { text_field.id.to_s => nil, select_field.id.to_s => 'Beaver' }
      result = page.send(:field_transcription_json_to_plaintext, json)
      expect(result).not_to include('Name:')
      expect(result).to include('County: Beaver')
    end

    it 'skips fields with blank string values' do
      json = { text_field.id.to_s => '', select_field.id.to_s => 'Beaver' }
      result = page.send(:field_transcription_json_to_plaintext, json)
      expect(result).not_to include('Name:')
    end

    context 'with a spreadsheet field' do
      let!(:spreadsheet_field) do
        create(:transcription_field, :spreadsheet_field,
               label: 'Witnesses', collection: collection, position: 3, line_number: 3)
      end
      let!(:col1) { create(:spreadsheet_column, label: 'First', transcription_field: spreadsheet_field, position: 1) }
      let!(:col2) { create(:spreadsheet_column, label: 'Last',  transcription_field: spreadsheet_field, position: 2) }

      it 'formats each row as "Label: col1_value col2_value"' do
        json = transcription_json.merge(
          spreadsheet_field.id.to_s => [
            { col1.id.to_s => 'Jane', col2.id.to_s => 'Doe' },
            { col1.id.to_s => 'Bob',  col2.id.to_s => 'Smith' }
          ]
        )
        result = page.send(:field_transcription_json_to_plaintext, json)
        expect(result).to include('Witnesses: Jane Doe')
        expect(result).to include('Witnesses: Bob Smith')
      end
    end

    context 'with description and instruction fields' do
      let!(:desc_field) do
        create(:transcription_field, :description_field,
               label: 'Section header', collection: collection, position: 3, line_number: 3)
      end
      let!(:instr_field) do
        create(:transcription_field, :instruction_field,
               label: 'How to fill', collection: collection, position: 4, line_number: 4)
      end

      it 'omits description and instruction fields from the output' do
        json = transcription_json.merge(
          desc_field.id.to_s  => 'Section header',
          instr_field.id.to_s => 'How to fill'
        )
        result = page.send(:field_transcription_json_to_plaintext, json)
        expect(result).not_to include('Section header')
        expect(result).not_to include('How to fill')
      end
    end
  end

  describe '#ground_truth_for_comparison' do
    context 'when the page has field-based transcription data' do
      let(:human_json) do
        { text_field.id.to_s => 'Jane Doe', select_field.id.to_s => 'Beaver' }
      end

      before { page.update!(transcription_json: human_json) }

      it 'returns only the field values joined by spaces (no labels)' do
        result = page.reload.ground_truth_for_comparison
        expect(result).to eq('Jane Doe Beaver')
        expect(result).not_to include('Name:')
        expect(result).not_to include('County:')
      end
    end

    context 'when transcription_json is blank' do
      it 'falls back to verbatim_transcription_plaintext' do
        allow(page).to receive(:verbatim_transcription_plaintext).and_return('plain text fallback')
        expect(page.ground_truth_for_comparison).to eq('plain text fallback')
      end
    end

    context 'when collection is not field_based' do
      let!(:non_field_collection) { create(:collection, owner_user_id: owner.id) }
      let!(:non_field_work) { create(:work, collection: non_field_collection) }
      let!(:non_field_page) { create(:page, work: non_field_work) }

      it 'returns verbatim_transcription_plaintext' do
        allow(non_field_page).to receive(:verbatim_transcription_plaintext).and_return('doc text')
        expect(non_field_page.ground_truth_for_comparison).to eq('doc text')
      end
    end

    context 'with a spreadsheet field' do
      let!(:spreadsheet_field) do
        create(:transcription_field, :spreadsheet_field,
               label: 'Witnesses', collection: collection, position: 3, line_number: 3)
      end
      let!(:col1) { create(:spreadsheet_column, label: 'First', transcription_field: spreadsheet_field, position: 1) }
      let!(:col2) { create(:spreadsheet_column, label: 'Last',  transcription_field: spreadsheet_field, position: 2) }

      before do
        page.update!(transcription_json: {
          text_field.id.to_s        => 'John',
          select_field.id.to_s      => 'Beaver',
          spreadsheet_field.id.to_s => [
            { col1.id.to_s => 'Jane', col2.id.to_s => 'Doe' },
            { col1.id.to_s => 'Bob',  col2.id.to_s => 'Smith' }
          ]
        })
      end

      it 'includes spreadsheet rows as space-joined column values, without labels' do
        result = page.reload.ground_truth_for_comparison
        expect(result).to include('Jane Doe')
        expect(result).to include('Bob Smith')
        expect(result).not_to include('Witnesses:')
      end
    end
  end
end
