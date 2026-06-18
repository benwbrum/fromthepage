require 'spec_helper'
require 'openai/description_tagger'

RSpec.describe DescriptionTagger do
  before do
    described_class.class_variable_set(:@@subject_prompt, nil) if described_class.class_variable_defined?(:@@subject_prompt)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read)
      .with(File.join(Rails.root, 'lib', 'openai', 'subject_prompt.txt'))
      .and_return("Tags: {{tags}}\nDescription: {{description}}")
    allow(described_class).to receive(:print)
    allow(described_class).to receive(:pp)
  end

  def stub_openai_response(content_or_response)
    response =
      if content_or_response.is_a?(Hash)
        content_or_response
      else
        { 'choices' => [{ 'message' => { 'content' => content_or_response } }] }
      end
    client = double('OpenAI::Client', chat: response)
    stub_const('OpenAI::Client', double('OpenAI::Client class', new: client))
    client
  end

  describe '.tag_description_by_subject' do
    it 'returns an empty array when choices are missing' do
      stub_openai_response({})

      expect(described_class.tag_description_by_subject('description', ['letters'])).to eq([])
    end

    it 'returns an empty array when the model says there is not enough information' do
      stub_openai_response('NOT ENOUGH INFORMATION')

      expect(described_class.tag_description_by_subject('description', ['letters'])).to eq([])
    end

    it 'parses a JSON array response' do
      stub_openai_response('["letters","diaries"]')

      expect(described_class.tag_description_by_subject('description', ['letters', 'diaries'])).to eq(['letters', 'diaries'])
    end

    it 'splits a JSON string response into cleaned tag names' do
      stub_openai_response('"letters, diaries"')

      expect(described_class.tag_description_by_subject('description', ['letters', 'diaries'])).to eq(['letters', 'diaries'])
    end

    it 'falls back to cleaned comma splitting for non-json responses' do
      stub_openai_response('POSSIBLE_TAGS: "letters", Tags: diaries, RESPONSE: journals')

      expect(described_class.tag_description_by_subject('description', ['letters', 'diaries', 'journals'])).to eq(['letters', 'diaries', 'journals'])
    end

    it 'sends a prompt containing tags, title, and description' do
      client = stub_openai_response('["letters"]')

      described_class.tag_description_by_subject('Body text', ['letters'], 'Title text')

      expect(client).to have_received(:chat).with(
        parameters: hash_including(
          messages: array_including(hash_including(role: 'user', content: "Tags: [\"letters\"]\nDescription: Title text\nBody text"))
        )
      )
    end
  end

  describe '.prompt_by_subject' do
    it 'substitutes tags and description into the prompt' do
      prompt = described_class.prompt_by_subject('Body text', ['letters'], '')

      expect(prompt).to eq("Tags: [\"letters\"]\nDescription: Body text")
    end

    it 'prepends the title when one is supplied' do
      prompt = described_class.prompt_by_subject('Body text', ['letters'], 'Title text')

      expect(prompt).to eq("Tags: [\"letters\"]\nDescription: Title text\nBody text")
    end
  end
end
