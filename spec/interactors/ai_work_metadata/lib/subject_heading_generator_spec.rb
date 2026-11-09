require 'spec_helper'

describe AiWorkMetadata::Lib::SubjectHeadingGenerator do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, collection: collection) }
  let!(:field) { create(:transcription_field, :as_metadata, label: 'Subject', input_type: 'subject_headings', collection: collection) }
  let!(:inventory) { field.create_subject_heading_inventory!(filename: 'headings.csv', row_count: 1, source_rows: []) }
  let!(:murder) { inventory.subject_headings.create!(heading: 'Murder', uri: 'http://id.loc.gov/authorities/subjects/sh85088613', normalized_key: 'murder') }

  let(:response_text) { '{"headings": [{"id": "H0001", "heading": "Murder"}]}' }
  let(:handler) { instance_double(AiWorkMetadata::Lib::Gemini::GenerateHandler, perform: [response_text, 'thinking', { total_token_count: 900 }, nil]) }

  before { allow(AiWorkMetadata::Lib::Gemini::GenerateHandler).to receive(:new).and_return(handler) }

  it 'sends the vocabulary as a cacheable system instruction to the subject heading model and asks for JSON' do
    described_class.new(work: work, field: field).perform

    expect(AiWorkMetadata::Lib::Gemini::GenerateHandler).to have_received(:new).with(
      hash_including(model: AiWorkMetadata::SUBJECT_HEADING_MODEL, json_response: true,
                     system_instruction: a_string_including('H0001 Murder'),
                     prompt: a_string_including("TITLE: #{work.title}"))
    )
  end

  it 'returns candidates, reasoning, and usage' do
    candidates, reasoning, usage = described_class.new(work: work, field: field).perform

    expect(candidates).to eq([murder.snapshot])
    expect(reasoning).to eq('thinking')
    expect(usage).to eq(total_token_count: 900, model: AiWorkMetadata::SUBJECT_HEADING_MODEL)
  end

  context 'when the response has no usable headings' do
    let(:response_text) { 'Sorry, I cannot help with that.' }

    it 'raises' do
      expect { described_class.new(work: work, field: field).perform }.to raise_error(ArgumentError, /could not be parsed/)
    end
  end

  context 'when the model returns no headings at all' do
    let(:response_text) { '{"headings": []}' }

    it 'returns no candidates without raising' do
      expect(described_class.new(work: work, field: field).perform.first).to eq([])
    end
  end
end
