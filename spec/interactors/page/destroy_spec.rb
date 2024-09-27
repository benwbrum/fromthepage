require 'spec_helper'

describe Page::Destroy do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, :with_image, work: work, status: :new) }

  let(:result) do
    described_class.call(page: page)
  end

  it 'deletes page' do
    expect(result.success?).to be_truthy
    expect(result.page.destroyed?).to be_truthy
  end
end
