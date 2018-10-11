# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Work, type: :model do
  let(:work) { build(:work) }

  describe '#supports_indexing?' do
    it "returns true if a work's collection does not have subjects disabled" do
      collection = work.collection
      collection.subjects_disabled = false

      expect(work.supports_indexing?).to be true
    end

    it "returns false if a work's collection has subjects disabled" do
      collection = work.collection
      collection.subjects_disabled = true

      expect(work.supports_indexing?).to be false
    end
  end
end
