require 'spec_helper'

describe SuspiciousBehaviors::Delete do
  let!(:user) { create(:unique_user) }
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }
  let!(:suspicious_behavior) { create(:suspicious_behavior, collection: collection, page: page, user: user, resolved_by_user_id: nil) }

  let(:result) do
    described_class.new(
      suspicious_behavior: suspicious_behavior,
      user: owner
    ).call
  end

  it 'destroys suspicious_behavior' do
    expect(result.success?).to be_truthy
    expect(result.suspicious_behavior.destroyed?).to be_truthy
  end

  context 'user is a collaborator' do
    let!(:collection) { create(:collection, owner_user_id: owner.id, collaborators: [user]) }

    let(:result) do
      described_class.new(
        suspicious_behavior: suspicious_behavior,
        user: user
      ).call
    end

    it 'destroys suspicious_behavior' do
      expect(result.success?).to be_truthy
      expect(result.suspicious_behavior.destroyed?).to be_truthy
    end
  end

  context 'user has no permission' do
    let(:result) do
      described_class.new(
        suspicious_behavior: suspicious_behavior,
        user: user
      ).call
    end

    it 'does not destroy suspicious_behavior' do
      expect(result.success?).to be_falsey
      expect(result.suspicious_behavior.destroyed?).to be_falsey
    end
  end
end
