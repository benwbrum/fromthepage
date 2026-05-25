require 'spec_helper'

describe AiTranscription::Lib::FieldBasedResponseValidator do
  let!(:owner)      { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, :field_based, owner_user_id: owner.id) }
  let!(:text_field) do
    create(:transcription_field, :text_field,
           label: 'Name', collection: collection, position: 1, line_number: 1)
  end
  let!(:select_field) do
    create(:transcription_field, :select_field,
           label: 'County', options: 'Beaver;Box Elder;Cache',
           collection: collection, position: 2, line_number: 2)
  end

  def validator_for(response_text)
    described_class.new(collection: collection, response_text: response_text)
  end

  def valid_json
    JSON.generate(text_field.id.to_s => 'John Smith', select_field.id.to_s => 'Beaver')
  end

  describe '#valid?' do
    it 'returns true for a well-formed JSON response with all required fields' do
      v = validator_for(valid_json)
      expect(v.valid?).to be true
      expect(v.errors).to be_empty
    end

    it 'allows null values for any field' do
      json = JSON.generate(text_field.id.to_s => nil, select_field.id.to_s => 'Beaver')
      expect(validator_for(json).valid?).to be true
    end

    it 'strips markdown ```json code fences before parsing' do
      fenced = "```json\n#{valid_json}\n```"
      expect(validator_for(fenced).valid?).to be true
    end

    it 'strips plain ``` code fences before parsing' do
      fenced = "```\n#{valid_json}\n```"
      expect(validator_for(fenced).valid?).to be true
    end

    it 'returns false for non-JSON text' do
      v = validator_for('not json at all')
      expect(v.valid?).to be false
      expect(v.errors.first).to include('Invalid JSON')
    end

    it 'returns false when required field keys are absent' do
      json = JSON.generate(text_field.id.to_s => 'John')
      v = validator_for(json)
      expect(v.valid?).to be false
      expect(v.errors.first).to include('Missing fields')
      expect(v.errors.first).to include(select_field.id.to_s)
    end

    context 'with a select field' do
      it 'accepts a value that appears in the options list' do
        json = JSON.generate(text_field.id.to_s => 'John', select_field.id.to_s => 'Box Elder')
        expect(validator_for(json).valid?).to be true
      end

      it 'rejects a value not present in the options list' do
        json = JSON.generate(text_field.id.to_s => 'John', select_field.id.to_s => 'InvalidCounty')
        v = validator_for(json)
        expect(v.valid?).to be false
        expect(v.errors.first).to include('County')
        expect(v.errors.first).to include('InvalidCounty')
      end

      context 'with semicolon-delimited options containing a placeholder first entry' do
        let!(:select_field) do
          create(:transcription_field, label: 'Sex',
                 input_type: 'select', options: 'Choose Sex;Female;Male;Other',
                 collection: collection, position: 2, line_number: 2)
        end

        it 'accepts a real option value from the list' do
          json = JSON.generate(text_field.id.to_s => 'John', select_field.id.to_s => 'Female')
          expect(validator_for(json).valid?).to be true
        end
      end

      context 'with trailing semicolons in options' do
        let!(:select_field) do
          create(:transcription_field, label: 'Amendment',
                 input_type: 'select', options: 'No;Yes;;',
                 collection: collection, position: 2, line_number: 2)
        end

        it 'ignores the blank entries and accepts a valid value' do
          json = JSON.generate(text_field.id.to_s => 'John', select_field.id.to_s => 'No')
          expect(validator_for(json).valid?).to be true
        end
      end
    end

    context 'with a spreadsheet field' do
      let!(:spreadsheet_field) do
        create(:transcription_field, :spreadsheet_field,
               label: 'Witnesses', collection: collection, position: 3, line_number: 3)
      end
      let!(:col1) { create(:spreadsheet_column, label: 'First', transcription_field: spreadsheet_field, position: 1) }
      let!(:col2) { create(:spreadsheet_column, label: 'Last',  transcription_field: spreadsheet_field, position: 2) }

      def full_json(spreadsheet_value)
        JSON.generate(
          text_field.id.to_s       => 'John',
          select_field.id.to_s     => 'Beaver',
          spreadsheet_field.id.to_s => spreadsheet_value
        )
      end

      it 'accepts an array of row hashes keyed by column ID' do
        rows = [{ col1.id.to_s => 'Jane', col2.id.to_s => 'Doe' }]
        expect(validator_for(full_json(rows)).valid?).to be true
      end

      it 'accepts null for the spreadsheet field' do
        expect(validator_for(full_json(nil)).valid?).to be true
      end

      it 'rejects a non-array spreadsheet value' do
        v = validator_for(full_json('not an array'))
        expect(v.valid?).to be false
        expect(v.errors.first).to include('Witnesses')
      end

      it 'rejects a row that is not an object' do
        v = validator_for(full_json(['not an object']))
        expect(v.valid?).to be false
      end
    end
  end

  describe '#parsed_json' do
    it 'returns the parsed hash after a successful validation' do
      v = validator_for(valid_json)
      v.valid?
      expect(v.parsed_json).to eq(
        text_field.id.to_s   => 'John Smith',
        select_field.id.to_s => 'Beaver'
      )
    end

    it 'returns nil when JSON cannot be parsed' do
      v = validator_for('bad json')
      v.valid?
      expect(v.parsed_json).to be_nil
    end
  end
end
