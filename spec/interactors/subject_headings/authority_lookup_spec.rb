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

  def stub_subject_request
    stub_request(:get, 'https://id.loc.gov/authorities/subjects/suggest2/')
      .with(query: { 'q' => 'Agriculture', 'count' => '5', 'searchtype' => 'keyword' })
  end

  def subject_request
    a_request(:get, 'https://id.loc.gov/authorities/subjects/suggest2/').with(query: hash_including('q' => 'Agriculture'))
  end

  it 'reads the LC contract across subjects, names and genre/forms, then caches results' do
    stub_subject_request.to_return(body: { count: 1, hits: [hit] }.to_json)
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
    stub_subject_request.to_timeout
    expect { service.call('Agriculture') }.to raise_error(described_class::LookupError)
    expect(delays).to include(2, 4)
    expect(subject_request).to have_been_made.times(3)
    expect { service.call('Agriculture') }.to raise_error(described_class::LookupError)
    expect(subject_request).to have_been_made.times(6)
  end

  [429, 500, 503].each do |status|
    it "retries HTTP #{status} then succeeds" do
      stub_subject_request.to_return(status: status).then.to_return(body: { count: 1, hits: [hit] }.to_json)
      expect(service.call('Agriculture')).to eq([hit])
      expect(subject_request).to have_been_made.twice
    end
  end

  [403, 404].each do |status|
    it "reports HTTP #{status} as a lookup error" do
      stub_subject_request.to_return(status: status)
      expect { service.call('Agriculture') }.to raise_error(described_class::LookupError, /#{status}/)
      expect(subject_request).to have_been_made.once
    end
  end

  ['not json', '{}', '{"count":1,"hits":[{"aLabel":"Term","uri":"http://attacker.example/1"}]}'].each do |body|
    it "rejects an unexpected response: #{body}" do
      stub_subject_request.to_return(body: body)
      expect { service.call('Agriculture') }.to raise_error(described_class::LookupError)
    end
  end

  it 'honors Retry-After seconds and logs the request, response and retry' do
    delays = []
    logger = double(info: nil, debug: nil, warn: nil, error: nil)
    service = described_class.new(cache: cache, sleeper: ->(n) { delays << n }, logger: logger)
    stub_subject_request.to_return(status: 429, headers: { 'Retry-After' => '120' }).then.to_return(body: { count: 0, hits: [] }.to_json)
    expect(service.call('Agriculture')).to eq([])
    expect(delays).to include(120)
    expect(logger).to have_received(:info).with(include('[LC authority] request', 'suggest2')).at_least(:once)
    expect(logger).to have_received(:info).with(include('"status":"429"', '"retry_after":"120"'))
    expect(logger).to have_received(:warn).with(include('"delay_seconds":120'))
  end

  it 'honors Retry-After HTTP dates with heartbeats during a long wait' do
    delays = []
    heartbeat = double(call: nil)
    allow(Time).to receive(:now).and_return(Time.utc(2026, 10, 31))
    service = described_class.new(cache: cache, sleeper: ->(n) { delays << n }, heartbeat: -> { heartbeat.call })
    stub_subject_request.to_return(status: 503, headers: { 'Retry-After' => (Time.now + 900).httpdate }).then.to_return(body: { count: 0, hits: [] }.to_json)
    expect(service.call('Agriculture')).to eq([])
    expect(delays.sum).to eq(901.0)
    expect(delays.max).to eq(30)
    expect(heartbeat).to have_received(:call).at_least(30).times
  end

  it 'backs off exponentially for throttling with an invalid header and keeps the HTTP status in the error' do
    delays = []
    service = described_class.new(cache: cache, sleeper: ->(n) { delays << n })
    stub_subject_request.to_return(status: 429, headers: { 'Retry-After' => 'invalid' })
    expect { service.call('Agriculture') }.to raise_error(described_class::LookupError, /HTTP 429/)
    expect(delays).to include(30, 60)
    expect(subject_request).to have_been_made.times(3)
  end
end
