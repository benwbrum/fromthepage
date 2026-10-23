require 'spec_helper'
require 'gemini/text_transcriber'

describe Gemini::TextTranscriber do
  describe '.transcribe_image' do
    let(:image_url) { 'http://example.com/image.jpg' }
    let(:image_data) { 'fake_image_data' }
    let(:encoded_data) { Base64.strict_encode64(image_data) }
    let(:api_key) { 'test_api_key' }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('GEMINI_API_KEY').and_return(api_key)
      allow(ENV).to receive(:[]).with('GEMINI_MODEL').and_return(nil)

      # Stub image fetching
      stub_request(:get, image_url)
        .to_return(status: 200, body: image_data)
    end

    context 'when API returns 503 error and then succeeds' do
      it 'retries with exponential backoff and eventually succeeds' do
        mock_client = double("GeminiClient")
        allow(Gemini).to receive(:new).and_return(mock_client)

        # First two calls raise 503, third succeeds
        call_count = 0
        allow(mock_client).to receive(:stream_generate_content) do
          call_count += 1
          if call_count <= 2
            raise StandardError.new('the server responded with status 503')
          else
            [{ 'candidates' => [{ 'content' => { 'parts' => [{ 'text' => 'Transcribed text' }] } }] }]
          end
        end

        # Mock sleep to speed up test
        allow_any_instance_of(Object).to receive(:sleep)

        result, _, _, _ = described_class.transcribe_image(image_url)
        expect(result).to eq('Transcribed text')
        expect(call_count).to eq(3)
      end
    end

    context 'when API returns 429 rate limit error and then succeeds' do
      it 'retries with exponential backoff and eventually succeeds' do
        mock_client = double("GeminiClient")
        allow(Gemini).to receive(:new).and_return(mock_client)

        # First two calls raise 429, third succeeds
        call_count = 0
        allow(mock_client).to receive(:stream_generate_content) do
          call_count += 1
          if call_count <= 2
            raise StandardError.new('the server responded with status 429')
          else
            [{ 'candidates' => [{ 'content' => { 'parts' => [{ 'text' => 'Transcribed text after rate limit' }] } }] }]
          end
        end

        # Mock sleep to speed up test
        allow_any_instance_of(Object).to receive(:sleep)

        result, _, _, _ = described_class.transcribe_image(image_url)
        expect(result).to eq('Transcribed text after rate limit')
        expect(call_count).to eq(3)
      end
    end

    context 'when API returns 503 error repeatedly' do
      it 'retries up to max_retries times then raises error' do
        mock_client = double("GeminiClient")
        allow(Gemini).to receive(:new).and_return(mock_client)

        # Always raise 503
        allow(mock_client).to receive(:stream_generate_content) do
          raise StandardError.new('the server responded with status 503')
        end

        # Mock sleep to speed up test
        allow_any_instance_of(Object).to receive(:sleep)

        expect {
          described_class.transcribe_image(image_url, max_retries: 2)
        }.to raise_error(StandardError, /503/)
      end
    end

    context 'when API returns 429 rate limit error repeatedly' do
      it 'retries up to max_retries times then raises error' do
        mock_client = double("GeminiClient")
        allow(Gemini).to receive(:new).and_return(mock_client)

        # Always raise 429
        allow(mock_client).to receive(:stream_generate_content) do
          raise StandardError.new('the server responded with status 429')
        end

        # Mock sleep to speed up test
        allow_any_instance_of(Object).to receive(:sleep)

        expect {
          described_class.transcribe_image(image_url, max_retries: 2)
        }.to raise_error(StandardError, /429/)
      end
    end

    context 'when API returns non-503/429 error' do
      it 'does not retry and raises error immediately' do
        mock_client = double("GeminiClient")
        allow(Gemini).to receive(:new).and_return(mock_client)

        call_count = 0
        allow(mock_client).to receive(:stream_generate_content) do
          call_count += 1
          raise StandardError.new('the server responded with status 400')
        end

        expect {
          described_class.transcribe_image(image_url)
        }.to raise_error(StandardError, /400/)
        expect(call_count).to eq(1)
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
end
