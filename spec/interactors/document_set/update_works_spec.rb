require 'spec_helper'

describe DocumentSet::UpdateWorks do
  let(:owner) { User.find_by(owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work_1) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:work_2) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id, works: [work_1]) }
  let(:work_params) do
    Hash[
      work_1.id.to_s, { included: 'false' },
      work_2.id.to_s, { included: 'true' }
    ]
  end

  let(:result) do
    described_class.new(document_set: document_set, work_params: work_params).call
  end

  it 'updates document_set works' do
    expect(result.success?).to be_truthy
    expect(result.document_set.work_ids).to eq([work_2.id])
  end
end
