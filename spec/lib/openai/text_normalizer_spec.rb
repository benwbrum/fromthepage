require 'spec_helper'
require 'openai/text_normalizer'

RSpec.describe TextNormalizer do
  before do
    described_class.class_variable_set(:@@normalize_prompt, nil) if described_class.class_variable_defined?(:@@normalize_prompt)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read)
      .with(File.join(Rails.root, 'lib', 'openai', 'normalizer_prompt.txt'))
      .and_return('Normalize this: {{text}}')
    allow(described_class).to receive(:print)
    allow(described_class).to receive(:pp)
  end

  def stub_openai_response(response)
    client = double('OpenAI::Client', chat: response)
    stub_const('OpenAI::Client', double('OpenAI::Client class', new: client))
    client
  end

  it 'returns an empty array when choices are missing' do
    stub_openai_response({})

    expect(described_class.normalize_text('raw text')).to eq([])
  end

  it 'returns an empty array when choices are empty' do
    stub_openai_response({ 'choices' => [] })

    expect(described_class.normalize_text('raw text')).to eq([])
  end

  it 'returns an empty array when the first choice has no message' do
    stub_openai_response({ 'choices' => [{}] })

    expect(described_class.normalize_text('raw text')).to eq([])
  end

  it 'returns normalized text from a successful response' do
    stub_openai_response({ 'choices' => [{ 'message' => { 'content' => 'Edited transcript' } }] })

    expect(described_class.normalize_text('raw text')).to eq('Edited transcript')
  end

  it 'strips a leading TEXT marker from successful responses' do
    stub_openai_response({ 'choices' => [{ 'message' => { 'content' => "TEXT Edited transcript" } }] })

    expect(described_class.normalize_text('raw text')).to eq('Edited transcript')
  end

  it 'sends a prompt with the raw text substituted' do
    client = stub_openai_response({ 'choices' => [{ 'message' => { 'content' => 'Done' } }] })

    described_class.normalize_text('original text')

    expect(client).to have_received(:chat).with(
      parameters: hash_including(messages: array_including(hash_including(role: 'user', content: 'Normalize this: original text')))
    )
  end
end
