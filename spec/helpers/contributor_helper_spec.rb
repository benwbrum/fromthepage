require 'spec_helper'

describe ContributorHelper do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:contributor) { create(:unique_user) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }

  before do
    User.current_user = owner
  end

  describe '#single_user_contributors' do
    let(:start_date) { 1.week.ago }
    let(:end_date) { Time.current }

    before do
      # Create some deeds for the contributor
      create(:deed, user: contributor, collection: collection, page: page, created_at: 3.days.ago)
      create(:deed, user: contributor, collection: collection, work: work, created_at: 2.days.ago)
    end

    it 'sets up single user contributor data' do
      helper.single_user_contributors(collection.id, start_date, end_date, contributor)

      expect(helper.instance_variable_get(:@collection)).to eq(collection)
      expect(helper.instance_variable_get(:@active_transcribers)).to eq([contributor])
      expect(helper.instance_variable_get(:@collection_deeds)).to be_present
      expect(helper.instance_variable_get(:@all_collaborators)).to eq([contributor])
      expect(helper.instance_variable_get(:@new_transcribers)).to eq([])
    end

    it 'filters deeds by date range' do
      # Create deed outside date range
      old_deed = create(:deed, user: contributor, collection: collection, page: page, created_at: 2.weeks.ago)
      
      helper.single_user_contributors(collection.id, start_date, end_date, contributor)
      
      collection_deeds = helper.instance_variable_get(:@collection_deeds)
      expect(collection_deeds).not_to include(old_deed)
      expect(collection_deeds.count).to eq(2) # Only the 2 deeds within range
    end

    it 'calculates user time from ahoy activity summary' do
      # Create ahoy activity summary
      create(:ahoy_activity_summary, 
        collection: collection, 
        user: contributor, 
        date: 2.days.ago, 
        minutes: 60
      )
      
      helper.single_user_contributors(collection.id, start_date, end_date, contributor)
      
      user_time = helper.instance_variable_get(:@user_time_proportional)
      expect(user_time[contributor.id]).to eq(60)
    end
  end

  describe '#new_contributors' do
    let(:start_date) { 1.week.ago }
    let(:end_date) { Time.current }

    before do
      create(:deed, user: contributor, collection: collection, page: page, created_at: 3.days.ago)
    end

    it 'sets up general contributor data' do
      helper.new_contributors(collection.id, start_date, end_date)

      expect(helper.instance_variable_get(:@collection)).to eq(collection)
      expect(helper.instance_variable_get(:@active_transcribers)).to include(contributor)
      expect(helper.instance_variable_get(:@collection_deeds)).to be_present
    end
  end
end