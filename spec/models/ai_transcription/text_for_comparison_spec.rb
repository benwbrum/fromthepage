require 'spec_helper'

describe AiTranscription, '#text_for_comparison' do
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

  context 'when collection is field_based and transcription_json is present' do
    let!(:ai_transcription) do
      create(:ai_transcription, page_id: page.id, status: :finished, source_text: nil,
             transcription_json: { text_field.id.to_s => 'John Smith', select_field.id.to_s => 'Beaver' })
    end

    it 'returns only field values joined by a space, no labels' do
      result = ai_transcription.text_for_comparison
      expect(result).to eq('John Smith Beaver')
      expect(result).not_to include('Name:')
      expect(result).not_to include('County:')
    end

    it 'skips nil and blank values' do
      ai_transcription.update!(transcription_json: {
        text_field.id.to_s   => nil,
        select_field.id.to_s => 'Beaver'
      })
      expect(ai_transcription.text_for_comparison).to eq('Beaver')
    end
  end

  context 'when collection is field_based but transcription_json is blank' do
    let!(:ai_transcription) do
      create(:ai_transcription, page_id: page.id, status: :finished,
             source_text: 'raw fallback text', transcription_json: nil)
    end

    it 'falls back to source_text' do
      expect(ai_transcription.text_for_comparison).to eq('raw fallback text')
    end
  end

  context 'when collection is not field_based' do
    let!(:standard_collection) { create(:collection, owner_user_id: owner.id) }
    let!(:standard_work)       { create(:work, collection: standard_collection) }
    let!(:standard_page)       { create(:page, work: standard_work) }
    let!(:ai_transcription) do
      create(:ai_transcription, page_id: standard_page.id, status: :finished,
             source_text: 'This is a plain document transcription')
    end

    it 'returns source_text unchanged' do
      expect(ai_transcription.text_for_comparison).to eq('This is a plain document transcription')
    end
  end

  context 'with a spreadsheet field' do
    let!(:spreadsheet_field) do
      create(:transcription_field, :spreadsheet_field,
             label: 'Witnesses', collection: collection, position: 3, line_number: 3)
    end
    let!(:col1) { create(:spreadsheet_column, label: 'First', transcription_field: spreadsheet_field, position: 1) }
    let!(:col2) { create(:spreadsheet_column, label: 'Last',  transcription_field: spreadsheet_field, position: 2) }

    let!(:ai_transcription) do
      create(:ai_transcription, page_id: page.id, status: :finished, source_text: nil,
             transcription_json: {
               text_field.id.to_s        => 'John',
               select_field.id.to_s      => 'Beaver',
               spreadsheet_field.id.to_s => [
                 { col1.id.to_s => 'Jane', col2.id.to_s => 'Doe' },
                 { col1.id.to_s => 'Bob',  col2.id.to_s => 'Smith' }
               ]
             })
    end

    it 'includes each row as space-joined column values' do
      result = ai_transcription.text_for_comparison
      expect(result).to include('Jane Doe')
      expect(result).to include('Bob Smith')
      expect(result).not_to include('Witnesses:')
    end
  end

  context 'with description and instruction fields in the collection' do
    let!(:desc_field) do
      create(:transcription_field, :description_field,
             label: 'Section header', collection: collection, position: 3, line_number: 3)
    end
    let!(:instr_field) do
      create(:transcription_field, :instruction_field,
             label: 'How to fill', collection: collection, position: 4, line_number: 4)
    end

    let!(:ai_transcription) do
      create(:ai_transcription, page_id: page.id, status: :finished, source_text: nil,
             transcription_json: {
               text_field.id.to_s   => 'John Smith',
               select_field.id.to_s => 'Beaver',
               desc_field.id.to_s   => 'Section header',
               instr_field.id.to_s  => 'How to fill'
             })
    end

    it 'omits description and instruction field values' do
      result = ai_transcription.text_for_comparison
      expect(result).not_to include('Section header')
      expect(result).not_to include('How to fill')
      expect(result).to include('John Smith')
    end
  end
end
