require 'spec_helper'
require 'chatgpt/text_transcriber'

describe Chatgpt::TextTranscriber do
  describe '.transcribe_image' do
    let(:image_url) { 'http://example.com/image.jpg' }
    let(:image_data) { 'fake_image_data' }
    let(:encoded_data) { Base64.strict_encode64(image_data) }
    let(:api_key) { 'test_api_key' }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(api_key)

      # Stub image fetching
      stub_request(:get, image_url)
        .to_return(status: 200, body: image_data)
    end

    context 'when API returns success' do
      it 'successfully transcribes the image' do
        mock_client = double("OpenAIClient")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)

        response = {
          'choices' => [
            {
              'message' => {
                'content' => 'Transcribed text from image'
              }
            }
          ]
        }

        allow(mock_client).to receive(:chat).and_return(response)

        result = described_class.transcribe_image(image_url)
        expect(result).to eq('Transcribed text from image')
      end
    end

    context 'when API returns 429 rate limit error and then succeeds' do
      it 'retries with exponential backoff and eventually succeeds' do
        mock_client = double("OpenAIClient")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)

        # First two calls raise 429, third succeeds
        call_count = 0
        allow(mock_client).to receive(:chat) do
          call_count += 1
          if call_count <= 2
            raise StandardError.new('the server responded with status 429')
          else
            {
              'choices' => [
                {
                  'message' => {
                    'content' => 'Transcribed text'
                  }
                }
              ]
            }
          end
        end

        # Mock sleep to speed up test
        allow_any_instance_of(Object).to receive(:sleep)

        result = described_class.transcribe_image(image_url)
        expect(result).to eq('Transcribed text')
        expect(call_count).to eq(3)
      end
    end

    context 'when API returns 503 error and then succeeds' do
      it 'retries with exponential backoff and eventually succeeds' do
        mock_client = double("OpenAIClient")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)

        # First two calls raise 503, third succeeds
        call_count = 0
        allow(mock_client).to receive(:chat) do
          call_count += 1
          if call_count <= 2
            raise StandardError.new('the server responded with status 503')
          else
            {
              'choices' => [
                {
                  'message' => {
                    'content' => 'Transcribed text'
                  }
                }
              ]
            }
          end
        end

        # Mock sleep to speed up test
        allow_any_instance_of(Object).to receive(:sleep)

        result = described_class.transcribe_image(image_url)
        expect(result).to eq('Transcribed text')
        expect(call_count).to eq(3)
      end
    end

    context 'when API returns retryable error repeatedly' do
      it 'retries up to max_retries times then raises error' do
        mock_client = double("OpenAIClient")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)

        # Always raise 429
        allow(mock_client).to receive(:chat) do
          raise StandardError.new('the server responded with status 429')
        end

        # Mock sleep to speed up test
        allow_any_instance_of(Object).to receive(:sleep)

        expect {
          described_class.transcribe_image(image_url, max_retries: 2)
        }.to raise_error(StandardError, /429/)
      end
    end

    context 'when API returns non-retryable error' do
      it 'does not retry and raises error immediately' do
        mock_client = double("OpenAIClient")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)

        call_count = 0
        allow(mock_client).to receive(:chat) do
          call_count += 1
          raise StandardError.new('the server responded with status 400')
        end

        expect {
          described_class.transcribe_image(image_url)
        }.to raise_error(StandardError, /400/)
        expect(call_count).to eq(1)
      end
    end

    context 'when OPENAI_API_KEY is not set' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
      end

      it 'raises an ArgumentError' do
        expect {
          described_class.transcribe_image(image_url)
        }.to raise_error(ArgumentError, 'OPENAI_API_KEY environment variable is not set')
      end
    end

    context 'when using custom model' do
      it 'uses the specified model' do
        mock_client = double("OpenAIClient")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)

        response = {
          'choices' => [
            {
              'message' => {
                'content' => 'Transcribed text'
              }
            }
          ]
        }

        expect(mock_client).to receive(:chat).with(
          hash_including(
            parameters: hash_including(
              model: 'gpt-4-turbo'
            )
          )
        ).and_return(response)

        described_class.transcribe_image(image_url, model: 'gpt-4-turbo')
      end
    end

    context 'when using custom prompt' do
      it 'uses the provided prompt' do
        mock_client = double("OpenAIClient")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)

        custom_prompt = 'Custom transcription instructions'
        response = {
          'choices' => [
            {
              'message' => {
                'content' => 'Transcribed text'
              }
            }
          ]
        }

        expect(mock_client).to receive(:chat).with(
          hash_including(
            parameters: hash_including(
              messages: array_including(
                hash_including(
                  content: array_including(
                    hash_including(text: custom_prompt)
                  )
                )
              )
            )
          )
        ).and_return(response)

        described_class.transcribe_image(image_url, prompt: custom_prompt)
      end
    end
  end

  describe '.fetch_and_encode_image' do
    let(:image_data) { 'fake_image_data' }
    let(:encoded_data) { Base64.strict_encode64(image_data) }

    context 'when URL returns success directly' do
      before do
        stub_request(:get, 'http://example.com/image.jpg')
          .to_return(status: 200, body: image_data)
      end

      it 'fetches and encodes the image' do
        result = described_class.fetch_and_encode_image('http://example.com/image.jpg')
        expect(result).to eq(encoded_data)
      end
    end

    context 'when URL returns a 302 redirect' do
      before do
        stub_request(:get, 'http://example.com/redirect.jpg')
          .to_return(status: 302, headers: { 'Location' => 'http://example.com/actual-image.jpg' })

        stub_request(:get, 'http://example.com/actual-image.jpg')
          .to_return(status: 200, body: image_data)
      end

      it 'follows the redirect and fetches the image' do
        result = described_class.fetch_and_encode_image('http://example.com/redirect.jpg')
        expect(result).to eq(encoded_data)
      end
    end

    context 'when URL returns multiple redirects' do
      before do
        stub_request(:get, 'http://example.com/redirect1.jpg')
          .to_return(status: 302, headers: { 'Location' => 'http://example.com/redirect2.jpg' })

        stub_request(:get, 'http://example.com/redirect2.jpg')
          .to_return(status: 301, headers: { 'Location' => 'http://example.com/actual-image.jpg' })

        stub_request(:get, 'http://example.com/actual-image.jpg')
          .to_return(status: 200, body: image_data)
      end

      it 'follows multiple redirects and fetches the image' do
        result = described_class.fetch_and_encode_image('http://example.com/redirect1.jpg')
        expect(result).to eq(encoded_data)
      end
    end

    context 'when URL returns too many redirects' do
      before do
        # Stub 11 redirects
        (0..10).each do |i|
          stub_request(:get, "http://example.com/redirect#{i}.jpg")
            .to_return(status: 302, headers: { 'Location' => "http://example.com/redirect#{i + 1}.jpg" })
        end
      end

      it 'raises an error for too many redirects' do
        expect {
          described_class.fetch_and_encode_image('http://example.com/redirect0.jpg')
        }.to raise_error(ArgumentError, 'Too many HTTP redirects')
      end
    end

    context 'when URL returns an error' do
      before do
        stub_request(:get, 'http://example.com/error.jpg')
          .to_return(status: 404, body: 'Not Found')
      end

      it 'raises an error' do
        expect {
          described_class.fetch_and_encode_image('http://example.com/error.jpg')
        }.to raise_error(/Failed to fetch image/)
      end
    end
  end

  describe '.extract_text_from_response' do
    context 'with valid response' do
      it 'extracts the text content' do
        response = {
          'choices' => [
            {
              'message' => {
                'content' => 'Extracted text content'
              }
            }
          ]
        }

        result = described_class.extract_text_from_response(response)
        expect(result).to eq('Extracted text content')
      end
    end

    context 'with response containing extra whitespace' do
      it 'strips whitespace from the content' do
        response = {
          'choices' => [
            {
              'message' => {
                'content' => "  \n  Text with whitespace  \n  "
              }
            }
          ]
        }

        result = described_class.extract_text_from_response(response)
        expect(result).to eq('Text with whitespace')
      end
    end

    context 'with unexpected response format' do
      it 'raises an error' do
        response = { 'unexpected' => 'format' }

        expect {
          described_class.extract_text_from_response(response)
        }.to raise_error(/Unexpected response format/)
      end
    end
  end

  describe '.default_prompt' do
    context 'when prompt file exists' do
      it 'loads the prompt from file' do
        allow(File).to receive(:read)
          .with(File.join(Rails.root, 'lib', 'chatgpt', 'transcription_prompt.txt'))
          .and_return('Custom prompt from file')

        expect(described_class.default_prompt).to eq('Custom prompt from file')
      end
    end

    context 'when prompt file does not exist' do
      it 'uses the fallback prompt' do
        allow(File).to receive(:read)
          .with(File.join(Rails.root, 'lib', 'chatgpt', 'transcription_prompt.txt'))
          .and_raise(Errno::ENOENT)

        prompt = described_class.default_prompt
        expect(prompt).to include('Please transcribe all the text')
        expect(prompt).to include('Do not add any commentary')
      end
    end
  end
end
