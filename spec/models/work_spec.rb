# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Work, type: :model do

  before :each do
    @user = create(:user)
  end

  after :each do
    @user.destroy
  end

  describe '#supports_indexing?' do
    it "returns true if a work's collection does not have subjects disabled" do
      collection = create(:collection, :with_pages, owner_user_id: @user.id, subjects_disabled: false)
      work = collection.works.first

      expect(work.supports_indexing?).to be true
    end

    it "returns false if a work's collection has subjects disabled" do
      collection = create(:collection, :with_pages, owner_user_id: @user.id, subjects_disabled: true)
      work = collection.works.first

      expect(work.supports_indexing?).to be false
    end
  end
end
