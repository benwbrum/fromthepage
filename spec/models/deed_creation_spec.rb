require 'spec_helper'

RSpec.describe "Deed Creation for Work Imports", type: :model do
  let(:user) { build(:owner) }
  let(:collection) { build(:collection, owner_user_id: user.id) }

  before do
    # Mock prerender methods to avoid complex rendering during tests
    allow_any_instance_of(Deed).to receive(:calculate_prerender)
    allow_any_instance_of(Deed).to receive(:calculate_prerender_mailer)
    
    # Save the user and collection for use in tests
    user.save!
    collection.save!
  end

  after do
    # Clean up any deeds created during tests to avoid interfering with other tests
    # This follows the same pattern as the existing deed_spec.rb test
    created_deed_ids.each { |id| Deed.destroy(id) } if defined?(@created_deed_ids)
    user.destroy if user.persisted?
    collection.destroy if collection.persisted?
  end

  def created_deed_ids
    @created_deed_ids ||= []
  end

  def track_deed(deed)
    @created_deed_ids ||= []
    @created_deed_ids << deed.id if deed.persisted?
    deed
  end

  describe "WORK_ADDED deed type inclusion" do
    it "includes WORK_ADDED in all_types" do
      expect(DeedType.all_types).to include(DeedType::WORK_ADDED)
    end

    it "includes WORK_ADDED in collection_edits for proper display" do
      expect(DeedType.collection_edits).to include(DeedType::WORK_ADDED)
    end

    it "excludes WORK_ADDED from contributor_types (by design for stats)" do
      expect(DeedType.contributor_types).not_to include(DeedType::WORK_ADDED)
    end
  end

  describe "record_deed functionality" do
    it "creates a WORK_ADDED deed with proper associations" do
      work = Work.new(title: "Test Work", collection: collection, owner: user)
      work.save!

      expect {
        deed = Deed.new
        deed.work = work
        deed.deed_type = DeedType::WORK_ADDED
        deed.collection = work.collection
        deed.user = work.owner
        deed.save!
        track_deed(deed)
      }.to change(Deed, :count).by(1)

      saved_deed = Deed.last
      expect(saved_deed.deed_type).to eq(DeedType::WORK_ADDED)
      expect(saved_deed.user).to eq(user)
      expect(saved_deed.collection).to eq(collection)
      expect(saved_deed.work).to eq(work)
      work.destroy
    end
  end

  describe "ScManifest record_deed method" do
    it "has the correct implementation for recording deeds" do
      sc_manifest = ScManifest.new
      work = Work.new(title: "IIIF Work", collection: collection, owner: user)
      work.save!

      expect {
        sc_manifest.send(:record_deed, work)
      }.to change(Deed, :count).by(1)

      deed = Deed.last
      track_deed(deed)
      expect(deed.deed_type).to eq(DeedType::WORK_ADDED)
      expect(deed.user).to eq(user)
      expect(deed.collection).to eq(collection)
      expect(deed.work).to eq(work)
      work.destroy
    end
  end

  describe "IaWork record_deed method" do
    it "has the correct implementation for recording deeds" do
      ia_work = IaWork.new
      work = Work.new(title: "IA Work", collection: collection, owner: user)
      work.save!

      expect {
        ia_work.send(:record_deed, work)
      }.to change(Deed, :count).by(1)

      deed = Deed.last
      track_deed(deed)
      expect(deed.deed_type).to eq(DeedType::WORK_ADDED)
      expect(deed.user).to eq(user)
      expect(deed.collection).to eq(collection)
      expect(deed.work).to eq(work)
      work.destroy
    end
  end

  describe "Work movement between collections" do
    it "should create a deed when work is moved to a different collection" do
      target_collection = Collection.new(title: "Target Collection", owner_user_id: user.id)
      target_collection.save!
      
      work = Work.new(title: "Moveable Work", collection: collection, owner: user)
      work.save!

      original_collection_id = work.collection_id
      work.collection = target_collection
      work.save!

      # Verify that collection actually changed
      expect(original_collection_id).not_to eq(work.collection_id)

      # Simulate the deed creation that should happen in WorkController#update
      expect {
        deed = Deed.new
        deed.work = work
        deed.deed_type = DeedType::WORK_ADDED
        deed.collection = work.collection
        deed.user = work.owner
        deed.save!
        track_deed(deed)
      }.to change(Deed, :count).by(1)

      deed = Deed.last
      expect(deed.deed_type).to eq(DeedType::WORK_ADDED)
      expect(deed.user).to eq(user)
      expect(deed.collection).to eq(target_collection)
      expect(deed.work).to eq(work)
      
      work.destroy
      target_collection.destroy
    end
  end

  describe "Deed visibility based on collection privacy" do
    it "marks deed as public when collection is public" do
      collection.restricted = false
      collection.save!
      
      work = Work.new(title: "Public Work", collection: collection, owner: user)
      work.save!
      
      deed = Deed.new(deed_type: DeedType::WORK_ADDED, work: work, collection: collection, user: user)
      deed.save!
      track_deed(deed)
      
      expect(deed.is_public).to be true
      work.destroy
    end

    it "marks deed as private when collection is restricted" do
      collection.restricted = true
      collection.save!
      
      work = Work.new(title: "Private Work", collection: collection, owner: user)
      work.save!
      
      deed = Deed.new(deed_type: DeedType::WORK_ADDED, work: work, collection: collection, user: user)
      deed.save!
      track_deed(deed)
      
      expect(deed.is_public).to be false
      work.destroy
    end
  end

  describe "Collection deed filtering for display" do
    it "includes WORK_ADDED deeds when filtering by collection_edits" do
      work = Work.new(title: "Display Test Work", collection: collection, owner: user)
      work.save!
      
      deed = Deed.new(deed_type: DeedType::WORK_ADDED, work: work, collection: collection, user: user)
      deed.save!
      track_deed(deed)
      
      collection_deed_types = DeedType.collection_edits
      filtered_deeds = collection.deeds.where(deed_type: collection_deed_types)
      
      expect(filtered_deeds).to include(deed)
      work.destroy
    end
  end
end