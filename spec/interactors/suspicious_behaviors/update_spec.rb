require 'spec_helper'

describe SuspiciousBehaviors::Update do
  let!(:user) { create(:unique_user) }
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }
  let!(:suspicious_behavior) { create(:suspicious_behavior, collection: collection, page: page, user: user, resolved_by_user_id: nil) }
  let(:status) { 'flagged' }

  let(:result) do
    described_class.new(
      suspicious_behavior: suspicious_behavior,
      status: status,
      user: owner
    ).call
  end

  it 'updates suspicious_behavior' do
    expect(result.success?).to be_truthy
    expect(result.suspicious_behavior.flagged?).to be_truthy
  end

  context 'user has no permission' do
    let(:result) do
      described_class.new(
        suspicious_behavior: suspicious_behavior,
        status: status,
        user: user
      ).call
    end

    it 'does not update suspicious_behavior' do
      expect(result.success?).to be_falsey
      expect(result.suspicious_behavior.flagged?).to be_falsey
    end
  end

  context 'invalid status' do
    let(:status) { 'invalid' }

    it 'does not update suspicious_behavior' do
      expect(result.success?).to be_falsey
      expect(result.suspicious_behavior.status).not_to eq('invalid')
    end
  end
end
