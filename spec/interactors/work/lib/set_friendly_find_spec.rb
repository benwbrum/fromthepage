require 'rails_helper'

RSpec.describe Work::Lib::SetFriendlyFind do
  describe '.perform' do
    let(:owner) { create(:owner) }
    let(:first_collection) { create(:collection, owner_user_id: owner.id) }
    let(:second_collection) { create(:collection, owner_user_id: owner.id) }

    let!(:first_work) { create(:work, collection: first_collection, owner: owner, slug: '123-work') }
    let!(:second_work) { create(:work, collection: second_collection, owner: owner, slug: "#{first_work.id}-text") }

    it 'resolves the work in the referenced collection when slug starts with a number' do
      found_work = described_class.perform(
        id: second_work.slug,
        collection_reference: second_collection
      )

      expect(found_work).to eq(second_work)
    end
  end
end
