require 'spec_helper'

RSpec.describe User, type: :model do
  describe '#last_deed_at' do
    let(:user) { create(:user) }

    it 'returns the created_at of the most recent deed' do
      allow_any_instance_of(Deed).to receive(:calculate_prerender)
      allow_any_instance_of(Deed).to receive(:calculate_prerender_mailer)
      older = create(:deed, user: user, deed_type: DeedType.all_types.first, created_at: 2.days.ago)
      newest = create(:deed, user: user, deed_type: DeedType.all_types.first, created_at: 1.day.ago)
      expect(user.last_deed_at.to_i).to eq(newest.created_at.to_i)
      Deed.destroy(older.id)
      Deed.destroy(newest.id)
    end
  end
end
