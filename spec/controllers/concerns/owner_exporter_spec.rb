require 'spec_helper'

RSpec.describe OwnerExporter do
  subject(:exporter) { Class.new { include OwnerExporter }.new }

  describe '#owner_mailing_list_csv' do
    let(:collection_one) { instance_double(Collection, id: 2, title: 'Collection Two') }
    let(:collection_two) { instance_double(Collection, id: 1, title: 'Collection One') }
    let(:owner) { instance_double(User, collections: [collection_one, collection_two]) }
    let(:user_one) do
      instance_double(User, id: 10, login: 'user-one', display_name: 'User One', email: 'one@example.com', activity_email: true)
    end
    let(:user_two) do
      instance_double(User, id: 11, login: 'user-two', display_name: 'User Two', email: 'two@example.com', activity_email: false)
    end
    let(:deed_counts) { { [user_one.id, 1] => 2, [user_one.id, 2] => 1, [user_two.id, 2] => 3 } }

    before do
      deed_relation = double('Deed relation')
      grouped_deeds = double('Grouped deed relation')
      allow(Deed).to receive(:where).with(collection_id: [1, 2]).and_return(deed_relation)
      allow(deed_relation).to receive(:group).with(:user_id, :collection_id).and_return(grouped_deeds)
      allow(grouped_deeds).to receive(:count).and_return(deed_counts)
      collection_relation = double('Collection relation')
      allow(Collection).to receive(:where).with(id: [1, 2]).and_return(collection_relation)
      allow(collection_relation).to receive(:order).with(:id).and_return([collection_two, collection_one])
      allow(User).to receive(:find).with([user_one.id, user_two.id]).and_return([user_one, user_two])
    end

    it 'exports users with deed counts per owner collection' do
      csv = CSV.parse(exporter.owner_mailing_list_csv(owner))

      expect(csv.first).to eq(['User Login', 'User Name', 'Email', 'Opt-In', 'Collection One', 'Collection Two'])
      expect(csv.second).to eq(['user-one', 'User One', 'one@example.com', 'true', '2', '1'])
      expect(csv.third).to eq(['user-two', 'User Two', 'two@example.com', 'false', '0', '3'])
    end
  end

  describe '#contributor_ids_for_dates' do
    let(:owner) { create(:unique_user, :owner) }
    let(:collection) { create(:collection, owner_user_id: owner.id) }
    let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
    let(:start_date) { 2.days.ago.beginning_of_day }
    let(:end_date) { 1.day.ago.end_of_day }
    let(:contributor) { create(:unique_user) }
    let(:joined_only_user) { create(:unique_user) }

    before do
      create(
        :deed,
        user: contributor,
        collection: collection,
        work: work,
        deed_type: DeedType::PAGE_TRANSCRIPTION,
        created_at: start_date + 2.hours
      )
      create(
        :deed,
        user: joined_only_user,
        collection: collection,
        work: work,
        deed_type: DeedType::COLLECTION_JOINED,
        created_at: start_date + 3.hours
      )
    end

    it 'excludes non-contribution collection join deeds' do
      contributor_ids = exporter.contributor_ids_for_dates([collection.id], start_date, end_date)

      expect(contributor_ids).to contain_exactly(contributor.id)
    end
  end
end
