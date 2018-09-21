# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Page, type: :model do
  let(:page) { build(:page) }

  describe '.indexed?' do
    it "returns true if a page's status is '#{Page::STATUS_INDEXED}'." do
      page.status = Page::STATUS_INDEXED
      expect(page.indexed?).to be true
    end

    it "returns false if a page's status is not '#{Page::STATUS_INDEXED}'." do
      page.status = nil
      expect(page.indexed?).to be false
    end
  end
end
