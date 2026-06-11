require 'spec_helper'

describe Work::Delete do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }

  let(:result) do
    described_class.new(
      work: work,
      user: owner
    ).call
  end

  it 'deletes work' do
    expect(result.success?).to be_truthy
    expect(result.work.persisted?).to be_falsey
  end

  context 'when user has no permission' do
    let!(:other_user) { create(:unique_user, :owner) }

    let(:result) do
      described_class.new(
        work: work,
        user: other_user
      ).call
    end

    it 'fails to delete' do
      expect(result.success?).to be_falsey
      expect(result.work.persisted?).to be_truthy
    end
  end
end
