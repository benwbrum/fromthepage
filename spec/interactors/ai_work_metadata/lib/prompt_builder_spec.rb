require 'spec_helper'

describe AiWorkMetadata::Lib::PromptBuilder do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) do
    create(:page, :transcribed, work: work,
           xml_text: "<?xml version='1.0' encoding='UTF-8'?><page><p>This is the transcribed page text.</p></page>")
  end

  let!(:text_field) do
    create(:transcription_field, :as_metadata, :text_field,
           label: 'Title', collection: collection, position: 1, line_number: 1)
  end

  let(:prompt) { described_class.new(work: work).build }

  it 'includes the field id and label' do
    expect(prompt).to include(text_field.id.to_s)
    expect(prompt).to include('Title')
  end

  it 'includes the document text' do
    expect(prompt).to include('This is the transcribed page text.')
  end

  it 'includes an example JSON block keyed by field id' do
    expect(prompt).to include("\"#{text_field.id}\": \"extracted text\"")
  end

  context 'when a select field with options exists' do
    let!(:select_field) do
      create(:transcription_field, :as_metadata, :select_field,
             label: 'County', options: 'Beaver;Box Elder',
             collection: collection, position: 2, line_number: 2)
    end

    it 'lists the options in the field description' do
      expect(prompt).to include('options: [Beaver, Box Elder]')
    end

    it 'uses the first option as the example value' do
      expect(prompt).to include("\"#{select_field.id}\": \"Beaver\"")
    end
  end

  context 'when an instruction field exists' do
    let!(:instruction_field) do
      create(:transcription_field, :as_metadata, :instruction_field,
             label: 'Please be concise', collection: collection, position: 3, line_number: 3)
    end

    it 'includes the instruction text but excludes it from the example JSON' do
      expect(prompt).to include('Instruction: Please be concise')
      expect(prompt).not_to include("\"#{instruction_field.id}\":")
    end
  end

  context 'when the collection has description instructions' do
    let!(:collection) { create(:collection, owner_user_id: owner.id, works: [], description_instructions: 'Focus on names and dates.') }

    it 'includes the additional instructions' do
      expect(prompt).to include('Focus on names and dates.')
    end
  end
end
