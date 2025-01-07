require 'spec_helper'

describe Page::Reorder do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:work) { create(:work, collection: collection) }
  let!(:page_1) { create(:page, :with_image, work: work, position: 1) }
  let!(:page_2) { create(:page, :with_image, work: work, position: 2) }
  let!(:page_3) { create(:page, :with_image, work: work, position: 3) }
  let(:direction) {}

  let(:result) do
    described_class.call(page: page_2, direction: direction)
  end

  context 'it moves up' do
    let(:direction) { 'up' }

    it 'reorders pages' do
      expect(result.success?).to be_truthy

      expect(page_2.reload.position).to eq(1)
      expect(page_1.reload.position).to eq(2)
      expect(page_3.reload.position).to eq(3)
    end
  end

  context 'it moves down' do
    let(:direction) { 'down' }

    it 'reorders pages' do
      expect(result.success?).to be_truthy

      expect(page_1.reload.position).to eq(1)
      expect(page_3.reload.position).to eq(2)
      expect(page_2.reload.position).to eq(3)
    end
  end
end
