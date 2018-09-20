# frozen_string_literal: true

RSpec.describe Page, type: :model do
  let(:page) { build(:page) }

  describe 'a valid page' do
    context 'when has valid params' do
      xit 'is valid' do
        expect(page).to be_valid
      end
    end

    context '.indexed?' do
      it "returns true if a page's status is '#{Page::STATUS_INDEXED}'." do
        page.status = Page::STATUS_INDEXED
        expect(page.status).to be true
      end

      it "returns false if a page's status is not '#{Page::STATUS_INDEXED}'." do
        page.status = nil
        expect(page.status).to be false
      end
    end
  end
end
