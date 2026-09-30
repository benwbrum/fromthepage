require 'spec_helper'

describe AiWorkMetadata::Lib::ResponseValidator do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:text_field) do
    create(:transcription_field, :as_metadata, :text_field,
           label: 'Title', collection: collection, position: 1, line_number: 1)
  end
  let!(:select_field) do
    create(:transcription_field, :as_metadata, :select_field,
           label: 'County', options: 'Beaver;Box Elder',
           collection: collection, position: 2, line_number: 2)
  end

  let(:validator) { described_class.new(collection: collection, response_text: response_text) }

  context 'when the response is valid JSON with all expected keys' do
    let(:response_text) do
      { text_field.id.to_s => 'Sample title', select_field.id.to_s => 'Beaver' }.to_json
    end

    it 'is valid' do
      expect(validator.valid?).to be true
      expect(validator.errors).to be_empty
    end

    it 'parses the JSON' do
      validator.valid?
      expect(validator.parsed_json[text_field.id.to_s]).to eq('Sample title')
    end
  end

  context 'when the response is wrapped in markdown code fences' do
    let(:response_text) do
      "```json\n" + { text_field.id.to_s => 'Sample title', select_field.id.to_s => 'Beaver' }.to_json + "\n```"
    end

    it 'strips the fences and parses successfully' do
      expect(validator.valid?).to be true
    end
  end

  context 'when the response is not valid JSON' do
    let(:response_text) { 'this is not json' }

    it 'is invalid' do
      expect(validator.valid?).to be false
      expect(validator.errors.first).to include('Invalid JSON')
    end
  end

  context 'when a required field is missing' do
    let(:response_text) { { text_field.id.to_s => 'Sample title' }.to_json }

    it 'is invalid and reports the missing field' do
      expect(validator.valid?).to be false
      expect(validator.errors.first).to include('Missing fields')
      expect(validator.errors.first).to include(select_field.id.to_s)
    end
  end

  context 'when a select field has an invalid value' do
    let(:response_text) do
      { text_field.id.to_s => 'Sample title', select_field.id.to_s => 'Not An Option' }.to_json
    end

    it 'is invalid' do
      expect(validator.valid?).to be false
      expect(validator.errors.first).to include('invalid select value')
    end
  end

  context 'when a multiselect field is present' do
    let!(:multiselect_field) do
      create(:transcription_field, :as_metadata,
             label: 'Topics', input_type: 'multiselect', options: 'History;Art',
             collection: collection, position: 3, line_number: 3)
    end

    context 'with a valid array value' do
      let(:response_text) do
        {
          text_field.id.to_s => 'Sample title',
          select_field.id.to_s => 'Beaver',
          multiselect_field.id.to_s => ['History']
        }.to_json
      end

      it 'is valid' do
        expect(validator.valid?).to be true
      end
    end

    context 'with a non-array value' do
      let(:response_text) do
        {
          text_field.id.to_s => 'Sample title',
          select_field.id.to_s => 'Beaver',
          multiselect_field.id.to_s => 'History'
        }.to_json
      end

      it 'is invalid' do
        expect(validator.valid?).to be false
        expect(validator.errors.first).to include('expected array for multiselect field')
      end
    end

    context 'with an invalid option in the array' do
      let(:response_text) do
        {
          text_field.id.to_s => 'Sample title',
          select_field.id.to_s => 'Beaver',
          multiselect_field.id.to_s => ['Not An Option']
        }.to_json
      end

      it 'is invalid' do
        expect(validator.valid?).to be false
        expect(validator.errors.first).to include('invalid multiselect value')
      end
    end
  end
end
