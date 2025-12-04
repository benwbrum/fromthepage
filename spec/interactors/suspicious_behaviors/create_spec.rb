require 'spec_helper'

describe SuspiciousBehaviors::Create do
  let!(:user) { create(:unique_user) }
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }
  let!(:suspicious_behavior) { create(:suspicious_behavior, collection: collection, page: page, user: user, resolved_by_user_id: nil) }

  let(:suspicious_behavior_params) do
    {
      behavior_type: 'large_paste',
      metadata: {
        content: "a" * 50
      }
    }
  end

  let(:result) do
    described_class.new(
      collection: collection,
      page: page,
      user: user,
      suspicious_behavior_params: suspicious_behavior_params
    ).call
  end

  it 'creates suspicious_behavior' do
    expect(result.success?).to be_truthy
    expect(result.suspicious_behavior).to have_attributes(
      collection_id: collection.id,
      page_id: page.id,
      user_id: user.id,
      behavior_type: 'large_paste',
      status: 'pending',
      resolved_at: nil,
      resolved_by_user_id: nil
    )
  end

  context 'user is greenlisted' do
    let!(:resolved_report) do
      create(:suspicious_behavior, collection: collection, page: page, user: user, resolved_by_user_id: owner,
        resolved_at: Time.current, status: :ignored)
    end

    it 'does not create suspicious_behavior' do
      expect(result.success?).to be_truthy
      expect(result.suspicious_behavior).to be_nil
    end
  end
end
