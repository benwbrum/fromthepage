require 'spec_helper'

describe SubjectHeadings::Import, :subject_headings do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: collection, input_type: 'subject_headings') }

  it 'imports a one-column inventory immediately without validation' do
    inventory = import_headings(field, "heading\nAbolitionists\nAgriculture\n")
    expect(inventory.row_count).to eq(2)
    expect(inventory.validation_status).to eq('not_requested')
    expect(inventory.subject_headings.pluck(:heading)).to contain_exactly('Abolitionists', 'Agriculture')
  end

  it 'preserves optional URIs and owner instructions' do
    inventory = import_headings(field, instructions: 'Prefer specific topics.')
    expect(inventory.subject_headings.first.uri).to eq('https://id.loc.gov/authorities/subjects/sh85002415')
    expect(field.reload.subject_heading_instructions).to eq('Prefer specific topics.')
  end

  it 'ignores suggestions and all additional informational columns' do
    inventory = import_headings(field, "heading,uri,suggested_heading,suggested_uri,result,rationale,decision\nLocal term,,Agriculture,http://example.org/wrong,exact_match,Text,yes\n")
    expect(inventory.subject_headings.first.attributes.slice('heading', 'uri')).to eq('heading' => 'Local term', 'uri' => nil)
  end

  it 'continues to recognize old reports without authority_type and ignores the new column' do
    legacy = "heading,uri,suggested_heading,suggested_uri,result,rationale\n'=1+1,,Other,https://example.org/other,possible_match,Review\n"
    expect(import_headings(field, legacy).source_rows).to eq([{ 'heading' => '=1+1', 'uri' => nil }])
    current = SubjectHeadings::Report.generate([{ 'heading' => '=1+1', 'authority_type' => 'Name' }])
    expect(import_headings(field, current).source_rows).to eq([{ 'heading' => '=1+1', 'uri' => nil }])
  end

  it 'handles BOM, CRLF, quoted commas, blank rows and surrounding whitespace' do
    inventory = import_headings(field, "\uFEFFheading,uri\r\n\r\n\" Politics, local \",\r\n,\r\nAgriculture,\r\n")
    expect(inventory.source_rows.map { |r| r['heading'] }).to eq(['Politics, local', 'Agriculture'])
  end

  it 'imports legacy Windows spreadsheet text without losing accents or punctuation' do
    heading = 'Élections européennes — conférences françaises'
    inventory = import_headings(field, "heading,uri\r\n#{heading},\r\n".encode('Windows-1252'))
    expect(inventory.source_rows).to eq([{ 'heading' => heading, 'uri' => nil }])
  end

  { 'UTF-16LE' => "\xFF\xFE".b, 'UTF-16BE' => "\xFE\xFF".b, 'UTF-32LE' => "\xFF\xFE\x00\x00".b }.each do |encoding, bom|
    it "imports #{encoding} spreadsheet CSV with a byte-order mark" do
      content = "heading,uri\r\nÉlections,https://example.org/authority\r\n"
      inventory = import_headings(field, bom + content.encode(encoding).b)
      expect(inventory.source_rows).to eq([{ 'heading' => 'Élections', 'uri' => 'https://example.org/authority' }])
    end
  end

  it 'reports unreadable text clearly and preserves the existing inventory' do
    original = import_headings(field)
    allow(CharlockHolmes::EncodingDetector).to receive(:detect).and_return(nil)
    expect { import_headings(field, "heading\n\xFF".b) }.to raise_error(described_class::ImportError, /could not be read/)
    expect(field.reload.subject_heading_inventory.id).to eq(original.id)
  end

  it 'deduplicates identical labels and terminal periods, retaining singulars and subdivisions' do
    rows = ['African Americans', 'African Americans', 'African Americans.', 'African American', 'Absence without leave', 'Absence without leave--Law and legislation', 'Administrative procedure-Mississippi.']
    inventory = import_headings(field, "heading\n#{rows.join("\n")}\n")
    expect(inventory.row_count).to eq(7)
    expect(inventory.source_rows.size).to eq(7)
    expect(inventory.subject_headings.count).to eq(5)
    expect(inventory.subject_headings.pluck(:heading)).not_to include('African Americans.')
  end

  it 'keeps different URIs separate rather than silently discarding identifiers' do
    inventory = import_headings(field, "heading,uri\nTerm,http://example.org/a\nTerm,http://example.org/b\nTerm,\n")
    expect(inventory.subject_headings.count).to eq(3)
  end

  {
    'missing heading column' => 'label,uri\nAgriculture,',
    'empty file' => '',
    'headers only' => "heading\n",
    'blank rows only' => "heading\n\n",
    'malformed quotation' => "heading\n\"unterminated",
    'missing row heading' => "heading,uri\n,http://example.org/a\n",
    'unsupported identifier' => "heading,uri\nTerm,sh85002415\n",
    'unsafe URI' => "heading,uri\nTerm,javascript:alert(1)\n",
    'oversized heading' => "heading\n#{'a' * 1001}\n"
  }.each do |name, content|
    it "clearly rejects #{name}" do
      expect { import_headings(field, content) }.to raise_error(described_class::ImportError)
      expect(field.reload.subject_heading_inventory).to be_nil
    end
  end

  it 'rejects file-size and row-count violations' do
    stub_const('SubjectHeadings::Import::MAX_BYTES', 10)
    expect { import_headings(field, "heading\nAgriculture\n") }.to raise_error(described_class::ImportError, /5 MB/)
    stub_const('SubjectHeadings::Import::MAX_BYTES', 5.megabytes)
    stub_const('SubjectHeadings::Import::MAX_ROWS', 1)
    expect { import_headings(field, "heading\nFirst\nSecond\n") }.to raise_error(described_class::ImportError, /10,000/)
  end

  it 'rejects null bytes and non-file upload parameters clearly' do
    expect { import_headings(field, "heading\nInvalid\0term\n") }.to raise_error(described_class::ImportError, /null bytes/)
    expect { described_class.new(field: field, upload: 'not an upload').call }.to raise_error(described_class::ImportError, /Choose a CSV/)
  end

  it 'atomically replaces options and retains the original inventory on malformed replacement' do
    original = import_headings(field)
    expect { import_headings(field, 'bad') }.to raise_error(described_class::ImportError)
    expect(field.reload.subject_heading_inventory.id).to eq(original.id)
    replacement = import_headings(field, "heading\nLocal term\n")
    expect(SubjectHeadingInventory.exists?(original.id)).to be(false)
    expect(replacement.subject_headings.pluck(:heading)).to eq(['Local term'])
  end

  it 'round-trips an unedited formula-safe report without accepting suggestions' do
    rows = ['=1+1', "'=1+1", '-Local term', '@institution', 'Agriculture'].map { |h| { 'heading' => h, 'uri' => nil, 'suggested_heading' => 'Wrong choice' } }
    report = SubjectHeadings::Report.generate(rows)
    expect(CSV.parse(report.delete_prefix("\uFEFF"), headers: true).first['heading']).to eq("'=1+1")
    expect(import_headings(field, report).source_rows.map { |r| r['heading'] }).to eq(rows.map { |r| r['heading'] })
  end

  it 'imports 3,000 options without a serialized options list' do
    inventory = import_headings(field, "heading\n#{3000.times.map { |i| "Legacy topic #{i}" }.join("\n")}\n")
    expect(inventory.subject_headings.count).to eq(3000)
    expect(field.reload.options).to be_nil
  end
  it 'round-trips a near-limit inventory through a report larger than the ordinary upload limit' do
    rows = 5200.times.map { |i| { 'heading' => format('%04d', i) + ('x' * 990), 'uri' => nil } }
    csv = CSV.generate { |out| out << %w[heading uri]; rows.each { |row| out << row.values } }
    expect(csv.bytesize).to be_between(described_class::MAX_BYTES * 0.98, described_class::MAX_BYTES)
    inventory = import_headings(field, csv)
    report = SubjectHeadings::Report.generate(rows.map { |row| row.merge('rationale' => 'Advisory explanation. ' * 20) })
    expect(report.bytesize).to be > described_class::MAX_BYTES
    replacement = import_headings(field, report)
    expect(replacement.source_rows).to eq(inventory.source_rows)
    expect(replacement.subject_headings.count).to eq(5200)
  end
end
