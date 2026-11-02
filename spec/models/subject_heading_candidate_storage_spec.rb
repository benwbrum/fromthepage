require 'spec_helper'

describe 'Reserved subject heading candidate storage', :subject_headings, type: :model do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, collection: collection, owner: owner) }

  it 'round-trips the separate team’s JSON payload without defining a candidate format' do
    payload = { 'external_pipeline' => { 'candidate_ids' => ['heading-1'], 'context' => ['Local term'] } }
    draft = create(:ai_work_metadata, work_id: work.id, subject_heading_candidates: payload)
    expect(draft.reload.subject_heading_candidates).to eq(payload)
  end

  it 'allows draft records with no subject heading candidates' do
    draft = create(:ai_work_metadata, work_id: work.id)
    expect(draft.reload.subject_heading_candidates).to be_nil
  end
end
