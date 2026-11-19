require 'spec_helper'

describe Deed::Calculate do
  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
  let!(:page) { create(:page, work: work) }

  let!(:deed) { create(:deed, deed_type: DeedType::PAGE_TRANSCRIPTION, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: user.id) }

  let(:result) do
    described_class.new(
      deed: deed
    ).call
  end

  it 'calculates prerenders and most_recent_deed values' do
    expect(deed.prerender).to be_nil
    expect(deed.prerender_mailer).to be_nil
    expect(collection.most_recent_deed_created_at).to be_nil
    expect(work.most_recent_deed_created_at).to be_nil

    expect(result.success?).to be_truthy

    deed.reload
    collection.reload
    work.reload

    expect(deed.prerender).to be_present
    expect(deed.prerender_mailer).to be_present
    expect(collection.most_recent_deed_created_at).to eq(deed.created_at)
    expect(work.most_recent_deed_created_at).to eq(deed.created_at)
  end
end
