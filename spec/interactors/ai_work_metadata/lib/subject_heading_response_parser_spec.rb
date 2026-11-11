require 'spec_helper'

describe AiWorkMetadata::Lib::SubjectHeadingResponseParser do
  let(:murder) { SubjectHeading.new(heading: 'Murder', uri: 'http://id.loc.gov/authorities/subjects/sh85088613') }
  let(:police) { SubjectHeading.new(heading: 'Police', uri: nil) }
  let(:prompt_builder) { instance_double(AiWorkMetadata::Lib::SubjectHeadingPromptBuilder) }
  let(:parser) { described_class.new(response_text: response_text, prompt_builder: prompt_builder) }

  before do
    allow(prompt_builder).to receive(:heading_for) { |id| { 'H0001' => murder, 'H0002' => police }[id] }
  end

  context 'with a valid response' do
    let(:response_text) { '{"headings": [{"id": "H0001", "heading": "Murder"}, {"id": "H0002", "heading": "Police"}]}' }

    it 'returns heading snapshots' do
      expect(parser.candidates).to eq([murder.snapshot, police.snapshot])
      expect(parser).not_to be_malformed
    end
  end

  context 'with ids that are not in the vocabulary and duplicates' do
    let(:response_text) { '{"headings": [{"id": "H0001"}, {"id": "H9999"}, {"id": "H0001"}, "Police"]}' }

    it 'keeps valid ids once and records the invalid ones' do
      expect(parser.candidates).to eq([murder.snapshot])
      expect(parser.invalid_ids).to eq(['H9999'])
    end
  end

  context 'with a markdown code fence' do
    let(:response_text) { "```json\n{\"headings\": [{\"id\": \"H0002\"}]}\n```" }

    it 'parses the JSON inside' do
      expect(parser.candidates).to eq([police.snapshot])
    end
  end

  context 'with a response cut off mid-JSON' do
    let(:response_text) { '{"headings": [{"id": "H0001", "heading": "Murder"}, {"id": "H0002", "head' }

    it 'salvages the ids' do
      expect(parser).to be_malformed
      expect(parser.candidates).to eq([murder.snapshot, police.snapshot])
    end
  end
end
