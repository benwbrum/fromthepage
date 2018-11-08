# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Collection, type: :model do
  describe '#is_public' do
    it 'returns true if a collection is not restricted' do
      user = build_stubbed(:user)
      collection = build_stubbed(:collection, owner_user_id: user.id, restricted: false)

      expect(collection.is_public).to be true
    end

    it 'returns false if a collection is restricted' do
      user = build_stubbed(:user)
      collection = build_stubbed(:collection, owner_user_id: user.id, restricted: true)

      expect(collection.is_public).to be false
    end
  end
end
