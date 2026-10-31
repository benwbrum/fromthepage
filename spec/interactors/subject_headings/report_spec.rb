require 'spec_helper'

describe SubjectHeadings::Report, :subject_headings do
  let(:row) { { 'heading' => 'Agriculture', 'uri' => 'http://local.example/old' } }
  let(:hit) { { 'evidence' => 'authority', 'authority_type' => 'Subject', 'variants' => [], 'aLabel' => 'Agriculture', 'suggestLabel' => 'Agriculture', 'uri' => 'http://id.loc.gov/authorities/subjects/sh85002415' } }

  it 'classifies exact evidence, leaving the active columns untouched' do
    result = described_class.result(row, [hit])
    expect(result.slice('heading', 'uri')).to eq(row)
    expect(result['result']).to eq('exact_match')
    expect(result['suggested_uri']).to eq(hit['uri'])
  end

  it 'identifies a variant only when LC provides the matching suggested label' do
    result = described_class.result(row, [hit.merge('aLabel' => 'Preferred term', 'variants' => ['Agriculture'])])
    expect(result['result']).to eq('variant_match')
  end

  it 'labels keyword candidates as possibilities' do
    result = described_class.result(row, [hit.merge('aLabel' => 'Farms', 'suggestLabel' => 'Farms')])
    expect(result['result']).to eq('possible_match')
  end

  it 'does not choose between multiple authorities' do
    result = described_class.result(row, [hit, hit.merge('uri' => 'http://id.loc.gov/authorities/names/n123')])
    expect(result['result']).to eq('multiple_authority_matches')
    expect(result['suggested_uri']).to include(hit['uri'], 'http://id.loc.gov/authorities/names/n123')
  end

  it 'never equates no match with invalidity' do
    expect(described_class.result(row, [])['result']).to eq('no_match_found')
    expect(described_class.result(row.merge('heading' => 'Agriculture--Mississippi'), [])['result']).to eq('no_match_found')
  end

  it 'serializes exactly the contract columns with BOM, CRLF, quoting and formula protection' do
    csv = described_class.generate([row.merge('rationale' => '=IMPORTXML("bad")', 'suggested_heading' => "A, B\nC")])
    parsed = CSV.parse(csv.delete_prefix("\uFEFF"), headers: true)
    expect(parsed.headers).to eq(described_class::HEADERS)
    expect(parsed.headers).not_to include('decision')
    expect(parsed.first['rationale']).to start_with("'=")
    expect(parsed.first['suggested_heading']).to eq("A, B\nC")
    expect(csv).to include("\r\n")
  end
end
