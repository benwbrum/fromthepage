require 'spec_helper'

describe ScCollectionsController, type: :controller do
  describe '#fetch_manifest' do
    let(:controller) { ScCollectionsController.new }
    let(:manifest_url) { 'https://texashistory.unt.edu/ark:/67531/metapth1741604/manifest/' }
    let(:mock_manifest_content) { '{"@context": "http://iiif.io/api/presentation/2/context.json", "@type": "sc:Manifest"}' }

    before do
      controller.instance_variable_set(:@raw_manifest, nil)
    end

    it 'fetches manifest with custom headers for SSL compatibility' do
      expected_options = {
        "Accept-Encoding" => "identity",
        "User-Agent"      => "FromThePage-IIIF/1.0",
        "Connection"      => "close",
        open_timeout: 10,
        read_timeout: 20,
        ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER
      }

      # Mock URI.open to verify it's called with the right parameters
      allow(URI).to receive(:open).with(
        manifest_url,
        expected_options
      ).and_return(double(read: mock_manifest_content))

      result = controller.send(:fetch_manifest, manifest_url)
      expect(result).to eq(mock_manifest_content)
    end

    it 'caches manifest content to avoid repeated requests' do
      allow(URI).to receive(:open).and_return(double(read: mock_manifest_content))

      # First call
      result1 = controller.send(:fetch_manifest, manifest_url)
      # Second call
      result2 = controller.send(:fetch_manifest, manifest_url)

      expect(result1).to eq(mock_manifest_content)
      expect(result2).to eq(mock_manifest_content)
      expect(URI).to have_received(:open).once
    end

    it 'retries on SSL errors up to 2 attempts' do
      call_count = 0
      allow(URI).to receive(:open) do
        call_count += 1
        if call_count <= 1
          raise OpenSSL::SSL::SSLError.new('SSL_read: unexpected eof while reading')
        else
          double(read: mock_manifest_content)
        end
      end

      result = controller.send(:fetch_manifest, manifest_url)
      expect(result).to eq(mock_manifest_content)
      expect(URI).to have_received(:open).twice
    end

    it 'retries on EOF errors up to 2 attempts' do
      call_count = 0
      allow(URI).to receive(:open) do
        call_count += 1
        if call_count <= 1
          raise EOFError.new('unexpected end of file')
        else
          double(read: mock_manifest_content)
        end
      end

      result = controller.send(:fetch_manifest, manifest_url)
      expect(result).to eq(mock_manifest_content)
      expect(URI).to have_received(:open).twice
    end

    it 'raises error after 2 failed attempts' do
      allow(URI).to receive(:open).and_raise(OpenSSL::SSL::SSLError.new('SSL_read: unexpected eof while reading'))

      expect {
        controller.send(:fetch_manifest, manifest_url)
      }.to raise_error(OpenSSL::SSL::SSLError)

      expect(URI).to have_received(:open).twice
    end

    it 'does not retry on other types of errors' do
      allow(URI).to receive(:open).and_raise(StandardError.new('Some other error'))

      expect {
        controller.send(:fetch_manifest, manifest_url)
      }.to raise_error(StandardError, 'Some other error')

      expect(URI).to have_received(:open).once
    end
  end
end
