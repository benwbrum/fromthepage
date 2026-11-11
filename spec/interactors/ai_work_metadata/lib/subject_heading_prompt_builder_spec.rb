require 'spec_helper'

describe AiWorkMetadata::Lib::SubjectHeadingPromptBuilder do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) do
    create(:collection, owner_user_id: owner.id, works: [], title: 'Governors Papers',
                        intro_block: '<p>Letters to the governor &amp; his staff.</p>')
  end
  let!(:work) { create(:work, collection: collection, title: 'Letter about a murder') }
  let!(:page) do
    create(:page, :transcribed, work: work,
           xml_text: "<?xml version='1.0' encoding='UTF-8'?><page><p>A colored man was charged with murder.</p></page>")
  end
  let!(:field) do
    create(:transcription_field, :as_metadata, label: 'Subject', input_type: 'subject_headings',
                                               collection: collection, subject_heading_instructions: instructions)
  end
  let(:instructions) { nil }
  let!(:inventory) do
    field.create_subject_heading_inventory!(filename: 'headings.csv', row_count: 2, source_rows: [])
  end
  let!(:murder) { inventory.subject_headings.create!(heading: 'Murder', uri: 'http://id.loc.gov/authorities/subjects/sh85088613', normalized_key: 'murder') }
  let!(:african_americans) { inventory.subject_headings.create!(heading: 'African Americans', uri: nil, normalized_key: 'african-americans') }

  let(:builder) { described_class.new(work: work, field: field) }

  it 'lists the vocabulary alphabetically with short ids' do
    expect(builder.system_instruction).to include("H0001 African Americans\nH0002 Murder")
  end

  it 'describes the collection from its title and intro block, without HTML' do
    expect(builder.system_instruction).to include("COLLECTION: Governors Papers\nLetters to the governor & his staff.")
  end

  it 'keeps the document out of the system instruction so it can be cached' do
    expect(builder.system_instruction).not_to include('charged with murder')
    expect(builder.user_prompt).to include("TITLE: Letter about a murder\n\nTRANSCRIPT:\nA colored man was charged with murder.")
  end

  context 'when the work has only an AI transcription' do
    let!(:page) { create(:page, status: :new, work: work) }

    before { create(:ai_transcription, page_id: page.id, status: :finished, source_text: 'A colored man was charged with murder.') }

    it 'sends the AI transcription, labelled as machine transcription' do
      expect(builder.user_prompt).to include("TRANSCRIPT (some or all of it is machine transcription and may contain errors):\nA colored man was charged with murder.")
    end
  end

  it 'maps ids back to headings' do
    expect(builder.heading_for('H0002')).to eq(murder)
    expect(builder.heading_for('H0001')).to eq(african_americans)
    expect(builder.heading_for('H0003')).to be_nil
    expect(builder.heading_for('H0000')).to be_nil
    expect(builder.heading_for('Murder')).to be_nil
  end

  it 'leaves out the local practice section when the field has no instructions' do
    expect(builder.system_instruction).not_to include('Local cataloging practice')
  end

  context 'when the field has local practice instructions' do
    let(:instructions) { 'Always assign the governor who received the letter.' }

    it 'includes them' do
      expect(builder.system_instruction).to include("Local cataloging practice for this collection")
      expect(builder.system_instruction).to include('Always assign the governor who received the letter.')
    end
  end
end
