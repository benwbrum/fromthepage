require 'spec_helper'

RSpec.describe SuspiciousBehavior, type: :model do
  context "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:page).optional }
    it { should belong_to(:collection) }
    it { should belong_to(:deed).optional }
    it { should belong_to(:resolved_by_user).class_name('User').optional }
  end

  context "validations" do
    it { should validate_inclusion_of(:behavior_type).in_array(SuspiciousBehavior::BEHAVIOR_TYPES) }
    it { should validate_inclusion_of(:status).in_array(SuspiciousBehavior::STATUSES) }
    it { should validate_presence_of(:flagged_at) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:collection) { create(:collection) }
    
    before do
      @pending_behavior = create(:suspicious_behavior, 
        user: user, 
        collection: collection,
        status: 'pending',
        flagged_at: 1.hour.ago
      )
      @resolved_behavior = create(:suspicious_behavior, 
        user: user, 
        collection: collection,
        status: 'dismissed',
        flagged_at: 2.hours.ago,
        resolved_at: 30.minutes.ago
      )
    end

    describe '.pending' do
      it 'returns only pending behaviors' do
        expect(SuspiciousBehavior.pending).to include(@pending_behavior)
        expect(SuspiciousBehavior.pending).not_to include(@resolved_behavior)
      end
    end

    describe '.resolved' do
      it 'returns only resolved behaviors' do
        expect(SuspiciousBehavior.resolved).to include(@resolved_behavior)
        expect(SuspiciousBehavior.resolved).not_to include(@pending_behavior)
      end
    end

    describe '.for_collection' do
      it 'returns behaviors for a specific collection' do
        other_collection = create(:collection)
        other_behavior = create(:suspicious_behavior, user: user, collection: other_collection)
        
        expect(SuspiciousBehavior.for_collection(collection)).to include(@pending_behavior)
        expect(SuspiciousBehavior.for_collection(collection)).not_to include(other_behavior)
      end
    end

    describe '.recent' do
      it 'returns behaviors ordered by most recent first' do
        expect(SuspiciousBehavior.recent.first).to eq(@pending_behavior)
      end
    end
  end

  describe '#first_offense?' do
    let(:user) { create(:user) }
    let(:collection) { create(:collection) }

    it 'returns true for the first suspicious behavior of a type' do
      behavior = create(:suspicious_behavior, 
        user: user, 
        collection: collection,
        behavior_type: 'paste_detected',
        flagged_at: Time.current
      )
      
      expect(behavior.first_offense?).to be true
    end

    it 'returns false if there was a prior behavior of the same type' do
      first_behavior = create(:suspicious_behavior, 
        user: user, 
        collection: collection,
        behavior_type: 'paste_detected',
        flagged_at: 1.hour.ago
      )
      
      second_behavior = create(:suspicious_behavior, 
        user: user, 
        collection: collection,
        behavior_type: 'paste_detected',
        flagged_at: Time.current
      )
      
      expect(second_behavior.first_offense?).to be false
    end
  end

  describe '#resolve!' do
    let(:user) { create(:user) }
    let(:resolver) { create(:user) }
    let(:collection) { create(:collection) }
    let(:behavior) { create(:suspicious_behavior, user: user, collection: collection) }

    it 'updates status and sets resolved_at' do
      behavior.resolve!(resolved_by: resolver, new_status: 'dismissed')
      
      expect(behavior.status).to eq('dismissed')
      expect(behavior.resolved_at).not_to be_nil
      expect(behavior.resolved_by_user).to eq(resolver)
    end
  end

  describe '#behavior_type_name' do
    let(:user) { create(:user) }
    let(:collection) { create(:collection) }
    let(:behavior) { create(:suspicious_behavior, user: user, collection: collection, behavior_type: 'paste_detected') }

    it 'returns humanized behavior type' do
      expect(behavior.behavior_type_name).to eq('Paste detected')
    end
  end
end
