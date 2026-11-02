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
    result = described_class.result(row, [hit, hit.merge('uri' => 'http://id.loc.gov/authorities/names/n123', 'authority_type' => 'Name')])
    expect(result['result']).to eq('multiple_authority_matches')
    expect(result['suggested_uri']).to be_nil
    expect(result['subject_candidates']).to include(hit['uri'])
    expect(result['name_candidates']).to include('http://id.loc.gov/authorities/names/n123')
    expect(result['genre_form_candidates']).to be_nil
  end

  it 'never equates no match with invalidity' do
    expect(described_class.result(row, [])['result']).to eq('no_match_found')
    expect(described_class.result(row.merge('heading' => 'Agriculture--Mississippi'), [])['result']).to eq('no_match_found')
  end

  it 'flags exact name labels for review without rejecting legitimate name subjects' do
    ['African American', 'American Missionary Association', 'Alcorn, James Lusk, 1816-1894'].each do |label|
      result = described_class.result(row.merge('heading' => label), [hit.merge('aLabel' => label, 'authority_type' => 'Name')])
      expect(result).to include('result' => 'possible_match', 'authority_type' => 'Name', 'suggested_uri' => hit['uri'])
      expect(result['rationale']).to include('confirm that the person, organization or place is the intended subject')
    end
  end

  it 'distinguishes duplicate records in one vocabulary and keeps alternatives out of suggested_uri' do
    result = described_class.result(row, [hit, hit.merge('uri' => 'https://id.loc.gov/authorities/subjects/sh999')])
    expect(result['result']).to eq('multiple_authority_matches')
    expect(result['rationale']).to eq('Multiple subject authority records share this label; review the records.')
    expect(result['suggested_uri']).to be_nil
    expect(result['suggested_heading']).to be_nil
    expect(result['subject_candidates']).to eq("Agriculture — #{hit['uri']}\nAgriculture — https://id.loc.gov/authorities/subjects/sh999")
    expect(result['name_candidates']).to be_nil
    expect(result['genre_form_candidates']).to be_nil
  end

  it 'groups verified alternatives into all three review-only columns and round-trips the original values' do
    label = '=Example, with punctuation'
    original = { 'heading' => label, 'uri' => 'https://example.org/local' }
    hits = [hit.merge('aLabel' => label),
      hit.merge('aLabel' => label, 'uri' => 'https://id.loc.gov/authorities/genreForms/gf123', 'authority_type' => 'Genre/form'),
      hit.merge('aLabel' => label, 'uri' => 'https://id.loc.gov/authorities/names/n123', 'authority_type' => 'Name')]
    result = described_class.result(original, hits)
    csv = described_class.generate([result])
    parsed = CSV.parse(csv.delete_prefix("\uFEFF"), headers: true)
    expect(parsed.headers).not_to include('candidate_uris')
    %w[subject_candidates genre_form_candidates name_candidates].zip(hits).each do |column, candidate|
      expect(parsed.first[column]).to eq("'#{label} — #{candidate['uri']}")
    end
    expect(parsed.first['suggested_uri']).to be_nil
    owner = create(:unique_user, :owner)
    collection = create(:collection, owner_user_id: owner.id, works: [])
    field = create(:transcription_field, :as_metadata, collection: collection, input_type: 'subject_headings')
    expect(import_headings(field, csv).source_rows).to eq([original])
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
