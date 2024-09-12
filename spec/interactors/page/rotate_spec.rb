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
    described_class.call(page: page, orientation: orientation)
  end

  it 'no changes' do
    expect(result.success?).to be_truthy

    expect(page.reload).to have_attributes(
      base_width: original_base_width,
      base_height: original_base_height
    )
  end

  context '90 degrees' do
    let(:orientation) { 90 }

    it 'rotates image' do
      expect(result.success?).to be_truthy

      expect(page.reload).to have_attributes(
        base_width: original_base_height,
        base_height: original_base_width
      )
    end
  end

  context '270 degrees' do
    let(:orientation) { 270 }

    it 'rotates image' do
      expect(result.success?).to be_truthy

      expect(page.reload).to have_attributes(
        base_width: original_base_width,
        base_height: original_base_height
      )
    end
  end
end
