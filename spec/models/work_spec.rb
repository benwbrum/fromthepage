# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Work, type: :model do
  let(:work) { build(:work) }

  describe '.supports_document_sets' do
    it "returns true if a work's collection supports document sets" do
      collection = work.collection
      collection.supports_document_sets = true

      expect(work.supports_document_sets).to be true
    end

    it "returns false if a work's collection does not support document sets" do
      collection = work.collection
      collection.supports_document_sets = false

      expect(work.supports_document_sets).to be false
    end
  end
end
