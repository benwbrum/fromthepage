require 'spec_helper'

describe 'Subject headings in AI metadata', :subject_headings do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: collection, input_type: 'subject_headings', label: 'Topics', subject_heading_instructions: 'Ignore passing mentions.') }
  let!(:work) { create(:work, collection: collection, owner: owner, title: 'Letter about agriculture') }
  let!(:inventory) { import_headings(field, "heading\nAgriculture\nFarmers\nNavigation\n") }

  it 'retrieves relevant candidates independently, allowing an empty result' do
    candidates = SubjectHeadings::Candidates.call(field: field, text: 'Agriculture and farmers')
    expect(candidates.values.map { |v| v['heading'] }).to contain_exactly('Agriculture', 'Farmers')
    expect(SubjectHeadings::Candidates.call(field: field, text: 'unrelated')).to eq({})
  end

  it 'limits candidate retrieval to forty and does not send the full inventory' do
    import_headings(field, "heading\n#{100.times.map { |i| "Agriculture #{i}" }.join("\n")}\nNavigation\n")
    candidates = SubjectHeadings::Candidates.call(field: field.reload, text: 'Agriculture')
    expect(candidates.size).to eq(40)
    builder = AiWorkMetadata::Lib::PromptBuilder.new(work: work)
    prompt = builder.build
    expect(builder.subject_heading_candidates.fetch(field.id.to_s).size).to eq(40)
    expect(prompt).not_to include('Navigation')
    expect(prompt).to include('Ignore passing mentions.', 'untrusted task data', 'candidate IDs')
  end

  it 'stores exactly the prompt candidates alongside the existing draft record' do
    result = AiWorkMetadata::Create.new(work: work, user: owner).call
    expect(result).to be_success
    draft = result.ai_work_metadata.reload
    expect(draft.subject_heading_candidates.fetch(field.id.to_s).values.map { |v| v['heading'] }).to eq(['Agriculture'])
    expect(work.reload.metadata_description).to be_nil
  end

  it 'converts supplied candidate IDs to trusted snapshots, including URIs' do
    candidates = { 'candidate_a' => { 'heading' => 'Agriculture', 'uri' => 'http://example.org/authority' } }
    validator = AiWorkMetadata::Lib::ResponseValidator.new(collection: collection, response_text: { field.id.to_s => ['candidate_a'] }.to_json, subject_heading_candidates: { field.id.to_s => candidates })
    expect(validator).to be_valid
    expect(validator.parsed_json.fetch(field.id.to_s)).to eq(candidates.values)
  end

  ['Invented heading', ['unknown_id'], [{ 'heading' => 'Agriculture', 'uri' => 'http://forged' }]].each do |value|
    it "rejects unconstrained AI output #{value.inspect}" do
      validator = AiWorkMetadata::Lib::ResponseValidator.new(collection: collection, response_text: { field.id.to_s => value }.to_json)
      expect(validator).not_to be_valid
    end
  end

  it 'accepts no-heading responses and rejects non-object JSON' do
    validator = AiWorkMetadata::Lib::ResponseValidator.new(collection: collection, response_text: { field.id.to_s => [] }.to_json)
    expect(validator).to be_valid
    validator = AiWorkMetadata::Lib::ResponseValidator.new(collection: collection, response_text: '[]')
    expect(validator).not_to be_valid
  end

  it 'uses the saved candidates during generation even if the inventory is replaced, preserving staff review' do
    candidate = inventory.subject_headings.first
    draft = create(:ai_work_metadata, work_id: work.id, metadata_json: nil, subject_heading_candidates: { field.id.to_s => { 'old_id' => candidate.snapshot } })
    import_headings(field, "heading\nReplacement\n")
    allow_any_instance_of(AiWorkMetadata::Lib::Gemini::GenerateHandler).to receive(:perform).and_return([{ field.id.to_s => ['old_id'] }.to_json, 'Reason', {}, nil])
    result = AiWorkMetadata::Generate.new(ai_work_metadata: draft).call
    expect(result).to be_success
    expect(draft.reload.metadata_json[field.id.to_s]).to eq([candidate.snapshot])
    expect(work.reload.metadata_description).to be_nil
  end
end
