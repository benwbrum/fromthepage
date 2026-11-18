require 'spec_helper'

describe ScCollectionsController, type: :controller do
  describe 'v2 manifest requests' do
    let(:manifest_url) { 'https://example.com/iiif/manifest' }
    let(:manifest_json) do
      {
        '@context' => 'http://iiif.io/api/presentation/2/context.json',
        '@id' => manifest_url,
        '@type' => 'sc:Manifest',
        'label' => 'Test manifest',
        'sequences' => []
      }.to_json
    end
    let!(:manifest_request) do
      stub_request(:get, manifest_url)
        .to_return(status: 200, body: manifest_json)
        .then.to_return(status: 403)
    end

    it 'previews a manifest with one request' do
      allow(controller).to receive(:params).and_return(at_id: manifest_url)
      expect(controller).to receive(:render).with('explore_manifest', at_id: manifest_url)

      controller.import

      expect(assigns(:sc_manifest).label).to eq('Test manifest')
      expect(manifest_request).to have_been_requested.once
    end

    it 'explores a manifest with one request' do
      allow(controller).to receive(:params).and_return(at_id: manifest_url)
      allow(controller).to receive(:set_collection)

      controller.explore_manifest

      expect(assigns(:sc_manifest).label).to eq('Test manifest')
      expect(manifest_request).to have_been_requested.once
    end

    it 'converts a manifest with one request' do
      owner = instance_double(User)
      collection = instance_double(Collection, owner: owner, text_entry?: false)
      work = instance_double(Work)
      allow(controller).to receive(:params).and_return(at_id: manifest_url, sc_manifest: { collection_id: '42' })
      allow(controller).to receive(:current_user).and_return(owner)
      allow(Collection).to receive(:find_by).with(id: '42').and_return(collection)
      allow(ScManifest).to receive(:new).and_wrap_original do |original|
        manifest = original.call
        expect(manifest).to receive(:convert_with_collection).with(owner, collection, nil, false).and_return(work)
        manifest
      end
      allow(controller).to receive(:describe_collection_work_path).with(owner, collection, work).and_return('/work')
      expect(controller).to receive(:redirect_to).with('/work')

      controller.convert_manifest

      expect(assigns(:sc_manifest).label).to eq('Test manifest')
      expect(manifest_request).to have_been_requested.once
    end
  end

  describe '#fetch_manifest' do
    let(:controller) { ScCollectionsController.new }
    let(:manifest_url) { 'https://texashistory.unt.edu/ark:/67531/metapth1741604/manifest/' }
    let(:mock_manifest_content) { '{"@context": "http://iiif.io/api/presentation/2/context.json", "@type": "sc:Manifest"}' }

    before do
      controller.instance_variable_set(:@raw_manifest, nil)
      allow(IiifHttp).to receive(:sleep)
    end

    it 'fetches manifest with custom headers for SSL compatibility' do
      expected_options = {
        'Accept-Encoding' => 'identity',
        'User-Agent' => 'FromThePage-IIIF/1.0',
        'Connection' => 'close',
        open_timeout: 10,
        read_timeout: 20,
        ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER
      }

      uri = URI.parse(manifest_url)
      allow(URI).to receive(:parse).with(manifest_url).and_return(uri)
      allow(uri).to receive(:open).with(expected_options).and_return(double(read: mock_manifest_content))

      result = controller.send(:fetch_manifest, manifest_url)
      expect(result).to eq(mock_manifest_content)
    end

    it 'rejects non-HTTP URLs before opening them' do
      expect { controller.send(:fetch_manifest, '|touch /tmp/pwned') }.to raise_error(URI::InvalidURIError)
      expect { controller.send(:fetch_manifest, 'file:///etc/passwd') }
        .to raise_error(ArgumentError, 'manifest URL must use HTTP or HTTPS')
    end

    it 'caches manifest content to avoid repeated requests' do
      uri = URI.parse(manifest_url).tap { |parsed| allow(parsed).to receive(:open).and_return(double(read: mock_manifest_content)) }
      allow(URI).to receive(:parse).and_return(uri)

      # First call
      result1 = controller.send(:fetch_manifest, manifest_url)
      # Second call
      result2 = controller.send(:fetch_manifest, manifest_url)

      expect(result1).to eq(mock_manifest_content)
      expect(result2).to eq(mock_manifest_content)
      expect(uri).to have_received(:open).once
    end

    it 'retries on SSL errors' do
      call_count = 0
      uri = URI.parse(manifest_url)
      allow(URI).to receive(:parse).and_return(uri)
      allow(uri).to receive(:open) do
        call_count += 1
        raise OpenSSL::SSL::SSLError.new('SSL_read: unexpected eof while reading') if call_count <= 1

        double(read: mock_manifest_content)
      end

      result = controller.send(:fetch_manifest, manifest_url)
      expect(result).to eq(mock_manifest_content)
      expect(uri).to have_received(:open).twice
    end

    it 'retries on EOF errors' do
      call_count = 0
      uri = URI.parse(manifest_url)
      allow(URI).to receive(:parse).and_return(uri)
      allow(uri).to receive(:open) do
        call_count += 1
        raise EOFError.new('unexpected end of file') if call_count <= 1

        double(read: mock_manifest_content)
      end

      result = controller.send(:fetch_manifest, manifest_url)
      expect(result).to eq(mock_manifest_content)
      expect(uri).to have_received(:open).twice
    end

    it 'raises error after the last failed attempt' do
      uri = URI.parse(manifest_url)
      allow(URI).to receive(:parse).and_return(uri)
      allow(uri).to receive(:open).and_raise(OpenSSL::SSL::SSLError.new('SSL_read: unexpected eof while reading'))

      expect do
        controller.send(:fetch_manifest, manifest_url)
      end.to raise_error(OpenSSL::SSL::SSLError)

      expect(uri).to have_received(:open).exactly(IiifHttp::ATTEMPTS).times
    end

    it 'does not retry on other types of errors' do
      uri = URI.parse(manifest_url)
      allow(URI).to receive(:parse).and_return(uri)
      allow(uri).to receive(:open).and_raise(StandardError.new('Some other error'))

      expect do
        controller.send(:fetch_manifest, manifest_url)
      end.to raise_error(StandardError, 'Some other error')

      expect(uri).to have_received(:open).once
    end

    it 'sets OpenSSL flag to ignore unexpected EOF when available' do
      # Mock the DEFAULT_PARAMS hash to track changes first
      default_params = { options: 0 }
      stub_const('OpenSSL::SSL::SSLContext::DEFAULT_PARAMS', default_params)

      # Mock OP_IGNORE_UNEXPECTED_EOF constant
      stub_const('OpenSSL::SSL::OP_IGNORE_UNEXPECTED_EOF', 0x80000)

      # Mock the OpenSSL constant check - allow it to be called with different arguments
      allow(OpenSSL::SSL).to receive(:const_defined?).and_call_original
      allow(OpenSSL::SSL).to receive(:const_defined?).with(:OP_IGNORE_UNEXPECTED_EOF).and_return(true)

      uri = URI.parse(manifest_url)
      allow(uri).to receive(:open).and_return(double(read: mock_manifest_content))
      allow(URI).to receive(:parse).and_return(uri)

      controller.send(:fetch_manifest, manifest_url)

      # Verify the flag was set
      expect(default_params[:options] & OpenSSL::SSL::OP_IGNORE_UNEXPECTED_EOF).to eq(OpenSSL::SSL::OP_IGNORE_UNEXPECTED_EOF)
    end

    it 'does not set OpenSSL flag when not available' do
      # Mock the DEFAULT_PARAMS hash
      default_params = { options: 0 }
      stub_const('OpenSSL::SSL::SSLContext::DEFAULT_PARAMS', default_params)

      # Mock the OpenSSL constant check to return false - allow other calls too
      allow(OpenSSL::SSL).to receive(:const_defined?).and_call_original
      allow(OpenSSL::SSL).to receive(:const_defined?).with(:OP_IGNORE_UNEXPECTED_EOF).and_return(false)

      uri = URI.parse(manifest_url)
      allow(uri).to receive(:open).and_return(double(read: mock_manifest_content))
      allow(URI).to receive(:parse).and_return(uri)

      controller.send(:fetch_manifest, manifest_url)

      # Verify the flag was not modified
      expect(default_params[:options]).to eq(0)
    end
  end
end
