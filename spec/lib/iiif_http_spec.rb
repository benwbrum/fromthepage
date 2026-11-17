require 'spec_helper'
require 'iiif_http'

describe IiifHttp do
  let(:url) { 'https://iiif.archive.org/iiif/mcht_c55_massey_26/manifest.json' }

  before do
    allow(described_class).to receive(:sleep)
  end

  it 'retries server errors and returns the body once one succeeds' do
    stub_request(:get, url)
      .to_return({ status: 502 }, { status: 500 }, { status: 200, body: '{"id":"ok"}' })

    expect(described_class.fetch_json(url)).to eq('id' => 'ok')
    expect(a_request(:get, url)).to have_been_made.times(3)
    expect(described_class).to have_received(:sleep).with(1).ordered
    expect(described_class).to have_received(:sleep).with(2).ordered
  end

  it 'retries timeouts' do
    stub_request(:get, url).to_timeout.then.to_return(status: 200, body: '{}')

    expect(described_class.fetch(url)).to eq('{}')
  end

  it 'gives up after the last attempt' do
    stub_request(:get, url).to_return(status: 502)

    expect { described_class.fetch(url) }.to raise_error(OpenURI::HTTPError, /502/)
    expect(a_request(:get, url)).to have_been_made.times(described_class::ATTEMPTS)
  end

  it 'does not retry client errors' do
    stub_request(:get, url).to_return(status: 404)

    expect { described_class.fetch(url) }.to raise_error(OpenURI::HTTPError, /404/)
    expect(a_request(:get, url)).to have_been_made.once
    expect(described_class).not_to have_received(:sleep)
  end

  it 'rejects non-HTTP URLs' do
    expect { described_class.fetch('file:///etc/passwd') }
      .to raise_error(ArgumentError, 'manifest URL must use HTTP or HTTPS')
  end
end
