require 'spec_helper'
require 'gemini/text_transcriber'

describe Gemini::TextTranscriber do
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
