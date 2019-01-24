require 'spec_helper'

RSpec.describe Deed, type: :model do
  context "associations" do
    it { should belong_to(:article) }
    it { should belong_to(:collection) }
    it { should belong_to(:note) }
    it { should belong_to(:page) }
    it { should belong_to(:user) }
    it { should belong_to(:work) }
  end

  context "validations" do
    it { should validate_inclusion_of(:deed_type).in_array(DeedType.all_types) }
  end

  describe '.order_by_recent_activity' do
    let(:deed_type) { DeedType.all_types.first }

    it 'lists deeds in order by most recently created' do
      first_deed = create(:deed, deed_type: deed_type)
      sleep(1)
      second_deed = create(:deed, deed_type: deed_type)

      expect(Deed.order_by_recent_activity.first).to eq(second_deed)

      # Tear down factories
      Deed.destroy(first_deed.id)
      Deed.destroy(second_deed.id)
    end
  end

  describe '.active' do
    let(:deed_type) { DeedType.all_types.first }

    it 'returns deeds by all active users' do
      inactive_user = create(:user, deleted: true)
      inactive_user_deed = create(:deed, deed_type: deed_type, user_id: inactive_user.id)
      active_user = create(:user)
      active_user_deed = create(:deed, deed_type: deed_type, user_id: active_user.id)

      expect(Deed.active).to include(active_user_deed)
      expect(Deed.active).to_not include(inactive_user_deed)

      # Tear down factories
      Deed.destroy(inactive_user_deed.id)
      Deed.destroy(active_user_deed.id)
      User.destroy(inactive_user.id)
      User.destroy(active_user.id)
    end
  end

  describe '.past_day' do
    let(:old_date) { 2.day.ago }
    let(:deed_type) { DeedType.all_types.first }

    it 'returns deeds created within the past day' do
      old_deed = create(:deed, deed_type: deed_type, created_at: old_date)
      deed_from_today = create(:deed, deed_type: deed_type)

      expect(Deed.past_day).to include(deed_from_today)
      expect(Deed.past_day).to_not include(old_deed)

      # Tear down factories
      Deed.destroy(old_deed.id)
      Deed.destroy(deed_from_today.id)
    end
  end

  describe '#deed_type_name' do
    let(:deed_type) { DeedType.all_types.first }

    it 'returns the human-readable name for the deed type' do
      deed = build(:deed, deed_type: deed_type)
      human_readable_name = DeedType::TYPES[deed_type]

      expect(deed.deed_type_name).to eq(human_readable_name)
    end
  end
end
