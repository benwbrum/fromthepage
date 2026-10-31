require 'spec_helper'

describe 'Evidence-based LC matching', :subject_headings do
  let(:service) { SubjectHeadings::AuthorityLookup.new(cache: ActiveSupport::Cache::MemoryStore.new, sleeper: ->(_) { }) }
  let(:mads) { SubjectHeadings::AuthorityLookup::MADS }

  before do
    SubjectHeadings::AuthorityLookup::SOURCES.each do |source|
      stub_request(:get, "https://id.loc.gov/authorities/#{source}/suggest2/")
        .with(query: hash_including('count' => '20'))
        .to_return(body: { count: 0, hits: [] }.to_json)
    end
  end

  def record(label, source: 'subjects', id: 'sh123', variants: [])
    uri = "https://id.loc.gov/authorities/#{source}/#{id}"
    nodes = [{ '@id' => uri, "#{mads}authoritativeLabel" => [{ '@value' => label }],
      "#{mads}hasVariant" => variants.each_index.map { |i| { '@id' => "_:v#{i}" } } }]
    variants.each_with_index { |variant, i| nodes << { '@id' => "_:v#{i}", "#{mads}variantLabel" => [{ '@value' => variant }] } }
    stub_request(:get, "#{uri}.madsrdf_raw.jsonld").to_return(body: nodes.to_json)
    { 'aLabel' => label, 'uri' => uri }
  end

  def search(query, hits, source: 'subjects', mode: 'leftanchored')
    stub_request(:get, "https://id.loc.gov/authorities/#{source}/suggest2/")
      .with(query: { 'q' => query, 'count' => '20', 'searchtype' => mode })
      .to_return(body: { count: hits.size, hits: hits }.to_json)
  end

  def result(heading, uri: nil)
    SubjectHeadings::Report.result({ 'heading' => heading, 'uri' => uri }, service.call(heading, identifier: uri))
  end

  ['African Americans', 'Agricultural laborers', 'American Missionary Association'].each do |heading|
    it "prefers the authorized #{heading} label over narrower or subordinate search results" do
      exact = record(heading)
      related = { 'aLabel' => "#{heading}--Related organization or activity", 'uri' => 'https://id.loc.gov/authorities/subjects/sh456' }
      search(heading, [related, exact])
      matched = result(heading)
      expect(matched['result']).to eq('exact_match')
      expect(matched['suggested_heading']).to eq(heading)
      expect(matched['authority_type']).to eq('Subject')
    end
  end

  { 'Acquisition of property.' => 'Acquisition of property', 'Alcohol.' => 'Alcohol', 'Alabama.Governor' => 'Alabama. Governor' }.each do |heading, authorized|
    it "retries conservative formatting for #{heading}" do
      hit = record(authorized)
      search(authorized, [hit])
      matched = result(heading)
      expect(matched['heading']).to eq(heading)
      expect(matched['result']).to eq('formatting_suggestion')
      expect(matched['suggested_heading']).to eq(authorized)
    end
  end

  %w[Account\ books Abstracts].each do |heading|
    it "reports multiple authorities for #{heading} only with verified matching labels" do
      subject = record(heading)
      genre = record(heading, source: 'genreForms', id: 'gf123')
      search(heading, [subject])
      search(heading, [genre], source: 'genreForms')
      matched = result(heading)
      expect(matched['result']).to eq('multiple_authority_matches')
      expect(matched['authority_type']).to eq('Subject; Genre/form')
      expect(matched['suggested_uri']).to include(subject['uri'], genre['uri'])
      expect(matched['rationale']).to eq('Same label appears in subject and genre/form authorities.')
    end
  end

  it 'does not make an unverified Alcorn suggestion into a documented name variant' do
    heading = 'Alcorn, James Lusk, 1816-1894'
    hit = record('Alcorn, James L., 1816-1894', source: 'names', id: 'n123')
    search(heading, [hit.merge('suggestLabel' => heading)], source: 'names')
    expect(result(heading)['result']).to eq('possible_match')
  end

  it 'recognizes Alcorn only when the authority graph explicitly records the variant' do
    heading = 'Alcorn, James Lusk, 1816-1894'
    hit = record('Alcorn, James L., 1816-1894', source: 'names', id: 'n123', variants: [heading])
    search(heading, [hit], source: 'names')
    expect(result(heading)).to include('result' => 'variant_match', 'authority_type' => 'Name')
  end

  it 'does not equate Aliens with loosely related keyword candidates' do
    hits = [record('Illegal immigration'), record('Noncitizens', id: 'sh456')]
    search('Aliens', hits, mode: 'keyword')
    matched = result('Aliens')
    expect(matched['result']).to eq('possible_match')
    expect(matched['suggested_uri']).to be_nil
    expect(matched['suggested_heading']).to be_nil
  end

  it 'can match Aliens when an authority explicitly establishes that variant' do
    hit = record('Noncitizens', variants: ['Aliens'])
    search('Aliens', [hit.merge('suggestLabel' => 'Aliens')], mode: 'keyword')
    expect(result('Aliens')['result']).to eq('variant_match')
  end

  it 'resolves an Alabama hit with a missing authorized-label hint through its authority record' do
    hit = record('Alabama', source: 'names', id: 'n123')
    search('Alabama', [hit.except('aLabel')], source: 'names')
    expect(result('Alabama')).to include('result' => 'exact_match', 'authority_type' => 'Name')
  end

  it 'never turns an unprocessable Alabama authority response into no match' do
    hit = record('Alabama')
    search('Alabama', [hit])
    stub_request(:get, "#{hit['uri']}.madsrdf_raw.jsonld").to_return(body: '{}')
    expect { result('Alabama') }.to raise_error(SubjectHeadings::AuthorityLookup::LookupError, 'Authority response could not be processed.')
  end

  it 'uses a supplied verified identifier to disambiguate without changing it' do
    hit = record('Account books', source: 'genreForms', id: 'gf123')
    expect(result('Account books', uri: hit['uri'])).to include('result' => 'exact_match', 'uri' => hit['uri'])
    expect(a_request(:get, /suggest2/)).not_to have_been_made
  end

  it 'reports a supplied-identifier mismatch while preserving both uploaded columns' do
    wrong = record('Alcohol', id: 'sh456')
    right = record('African Americans')
    search('African Americans', [right])
    expect(result('African Americans', uri: wrong['uri'])).to include('result' => 'exact_match', 'uri' => wrong['uri'])
    expect(result('African Americans', uri: wrong['uri'])['rationale']).to include('Supplied identifier identifies a different authority.')
  end
end
