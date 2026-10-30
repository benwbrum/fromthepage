require 'spec_helper'

describe SubjectHeadings::Selection, :subject_headings do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: collection, label: 'Topics', input_type: 'subject_headings') }
  let!(:work) { create(:work, collection: collection, owner: owner) }
  before { Current.user = owner }

  it 'saves text and URI snapshots and supports removal of all selected headings' do
    inventory = import_headings(field, "heading,uri\nAgriculture,https://id.loc.gov/authorities/subjects/sh85002415\nFarmers,\n")
    options = inventory.subject_headings.order(:id).to_a
    work.process_fields(field.id.to_s => { 'Topics' => options.map(&:selection_value) })
    work.save!
    saved = JSON.parse(work.reload.metadata_description).first['value']
    expect(saved).to eq(options.map(&:snapshot))
    work.process_fields(field.id.to_s => { 'Topics' => [''] })
    expect(JSON.parse(work.metadata_description).first['value']).to eq([])
  end

  it 'preserves retired headings after replacement and permits retaining or removing them' do
    old = import_headings(field).subject_headings.first.snapshot
    work.process_fields(field.id.to_s => { 'Topics' => [old.to_json] })
    work.save!
    before = work.metadata_description
    import_headings(field, "heading\nReplacement\n")
    expect(work.reload.metadata_description).to eq(before)
    work.process_fields(field.id.to_s => { 'Topics' => [old.to_json] })
    expect(JSON.parse(work.metadata_description).first['value']).to eq([old])
    expect { described_class.resolve(field: field.reload, values: [old.to_json]) }.to raise_error(ArgumentError)
  end

  it 'rejects arbitrary text, forged URIs, extra properties and malformed JSON' do
    option = import_headings(field).subject_headings.first.snapshot
    [option.merge('uri' => 'https://example.org/forged'), option.merge('heading' => 'Invented'), option.merge('extra' => 'bad')].each do |snapshot|
      expect { described_class.resolve(field: field, values: [snapshot.to_json]) }.to raise_error(ArgumentError)
    end
    expect { described_class.resolve(field: field, values: ['bad json']) }.to raise_error(ArgumentError)
  end

  it 'handles case-distinct headings even under a case-insensitive database collation' do
    inventory = import_headings(field, "heading\nLocal term\nlocal term\n")
    options = inventory.subject_headings.order(:id).to_a
    expect(described_class.resolve(field: field, values: options.map(&:selection_value))).to eq(options.map(&:snapshot))
  end

  it 'does not accept metadata fields from another collection' do
    other_collection = create(:collection, owner_user_id: owner.id, works: [])
    other_field = create(:transcription_field, :as_metadata, collection: other_collection)
    expect { work.process_fields(other_field.id.to_s => { 'Forged' => 'value' }) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
