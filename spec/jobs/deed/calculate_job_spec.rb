require 'spec_helper'

describe Deed::CalculateJob do
  include ActiveJob::TestHelper

  before do
    Current.user = user
  end

  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
  let!(:page) { create(:page, work: work) }

  let!(:deed) { create(:deed, deed_type: DeedType::PAGE_TRANSCRIPTION, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: user.id) }

  subject(:worker) { described_class.new }

  let(:perform_worker) do
    worker.perform(deed_id: deed.id, user_id: user.id)
  end

  it 'calculates prerenders and most_recent_deed values' do
    expect(deed.prerender).to be_nil
    expect(deed.prerender_mailer).to be_nil
    expect(collection.most_recent_deed_created_at).to be_nil
    expect(work.most_recent_deed_created_at).to be_nil

    perform_enqueued_jobs do
      perform_worker
    end

    deed.reload
    collection.reload
    work.reload

    expect(deed.prerender).to be_present
    expect(deed.prerender_mailer).to be_present
    expect(collection.most_recent_deed_created_at).to eq(deed.created_at)
    expect(work.most_recent_deed_created_at).to eq(deed.created_at)
  end
end
