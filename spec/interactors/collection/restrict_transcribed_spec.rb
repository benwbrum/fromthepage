require 'spec_helper'

describe Collection::RestrictTranscribed do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work_1) { create(:work, collection: collection) }
  let!(:work_statistic) { create(:work_statistic, work_id: work_1.id, complete: 100) }
  let!(:work_2) { create(:work, collection: collection) }

  let(:result) do
    described_class.new(collection: collection.reload).call
  end

  it 'restricts completed works' do
    expect(result.success?).to be_truthy
    expect(work_1.reload.restrict_scribes).to be_truthy
    expect(work_2.reload.restrict_scribes).to be_falsey
  end

  context 'when document set' do
    let(:document_set) do
      create(:document_set, collection_id: collection.id, owner_user_id: owner.id, works: [ work_1, work_2 ])
    end

    let(:result) do
      described_class.new(collection: document_set.reload).call
    end

    it 'restricts completed works' do
      expect(result.success?).to be_truthy
      expect(work_1.reload.restrict_scribes).to be_truthy
      expect(work_2.reload.restrict_scribes).to be_falsey
    end
  end
end
