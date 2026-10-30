require 'spec_helper'

describe SubjectHeadings::AuthorityLookup, :subject_headings do
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:sleeper) { ->(_) { } }
  let(:service) { described_class.new(cache: cache, sleeper: sleeper) }
  let(:hit) { { 'aLabel' => 'Agriculture', 'suggestLabel' => 'Agriculture', 'uri' => 'http://id.loc.gov/authorities/subjects/sh85002415' } }

  before do
    described_class::SOURCES.each do |source|
      stub_request(:get, "https://id.loc.gov/authorities/#{source}/suggest2/")
        .with(query: { 'q' => 'Agriculture', 'count' => '5', 'searchtype' => 'keyword' })
        .to_return(status: 200, body: { count: 0, hits: [] }.to_json)
    end
  end

  def subject_request
    a_request(:get, 'https://id.loc.gov/authorities/subjects/suggest2/').with(query: hash_including('q' => 'Agriculture'))
  end

  it 'reads the LC contract across subjects, names and genre/forms, then caches results' do
    stub_request(:get, /id.loc.gov\/authorities\/subjects\/suggest2/).to_return(body: { count: 1, hits: [hit] }.to_json)
    expect(service.call('Agriculture')).to eq([hit])
    expect(service.call('Agriculture')).to eq([hit])
    expect(subject_request).to have_been_made.once
  end

  it 'distinguishes a successful empty response from failed lookups' do
    expect(service.call('Agriculture')).to eq([])
  end

  it 'retries a timeout with backoff and does not cache failures' do
    delays = []
    service = described_class.new(cache: cache, sleeper: ->(n) { delays << n })
    stub_request(:get, /id.loc.gov\/authorities\/subjects\/suggest2/).to_timeout
    expect { service.call('Agriculture') }.to raise_error(described_class::LookupError)
    expect(delays).to include(0.5, 1.0)
    expect(subject_request).to have_been_made.times(3)
    expect { service.call('Agriculture') }.to raise_error(described_class::LookupError)
    expect(subject_request).to have_been_made.times(6)
  end

  [429, 500, 503].each do |status|
    it "retries HTTP #{status} then succeeds" do
      stub_request(:get, /id.loc.gov\/authorities\/subjects\/suggest2/).to_return(status: status).then.to_return(body: { count: 1, hits: [hit] }.to_json)
      expect(service.call('Agriculture')).to eq([hit])
      expect(subject_request).to have_been_made.twice
    end
  end

  [403, 404].each do |status|
    it "reports HTTP #{status} as a lookup error" do
      stub_request(:get, /id.loc.gov\/authorities\/subjects\/suggest2/).to_return(status: status)
      expect { service.call('Agriculture') }.to raise_error(described_class::LookupError, /#{status}/)
      expect(subject_request).to have_been_made.once
    end
  end

  ['not json', '{}', '{"count":1,"hits":[{"aLabel":"Term","uri":"http://attacker.example/1"}]}'].each do |body|
    it "rejects an unexpected response: #{body}" do
      stub_request(:get, /id.loc.gov\/authorities\/subjects\/suggest2/).to_return(body: body)
      expect { service.call('Agriculture') }.to raise_error(described_class::LookupError)
    end
  end
end
