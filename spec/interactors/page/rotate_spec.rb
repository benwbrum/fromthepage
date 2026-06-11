require 'spec_helper'

describe Page::Rotate do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, :with_image, work: work, position: 1) }
  let(:original_base_width) { 1581 }
  let(:original_base_height) { 570 }
  let(:orientation) { 0 }

  let(:result) do
    described_class.new(page: page, orientation: orientation).call
  end

  it 'no changes' do
    expect(result.success?).to be_truthy

    page.reload
    expect(page.base_width).to eq(original_base_width)
    expect(page.base_height).to eq(original_base_height)
  end

  context '90 degrees' do
    let(:orientation) { 90 }

    it 'rotates image' do
      expect(result.success?).to be_truthy

      page.reload
      expect(page.base_width).to eq(original_base_height)
      expect(page.base_height).to eq(original_base_width)
    end
  end

  context '270 degrees' do
    let(:orientation) { 270 }

    it 'rotates image' do
      expect(result.success?).to be_truthy

      page.reload
      expect(page.base_width).to eq(original_base_height)
      expect(page.base_height).to eq(original_base_width)
    end
  end

  context 'using legacy base_image' do
    let!(:page) { create(:page, :with_legacy_image, work: work, position: 1) }
    let(:orientation) { 90 }

    it 'rotates image' do
      expect(result.success?).to be_truthy

      page.reload
      expect(page.base_width).to eq(original_base_height)
      expect(page.base_height).to eq(original_base_width)
      expect(page.image.attached?).to be_truthy
    end
  end
end
