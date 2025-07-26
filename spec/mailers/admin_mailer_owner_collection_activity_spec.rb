require 'spec_helper'


RSpec.describe AdminMailer::OwnerCollectionActivity do
  describe ".build" do
      before :all do
        @owner = create(:user)
        @collection = create(:collection, owner_user_id: @owner.id)
        @new_collaborator = create(:user)
        @old_collaborator = create(:user)
        @new_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          collection_id: @collection.id,
          user_id: @old_collaborator.id
        })
        @old_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          collection_id: @collection.id,
          user_id: @old_collaborator.id,
          created_at: 2.days.ago
        })
      end
  
      after :each do
        @new_collaborator_deed.destroy if @new_collaborator_deed
      end
  
      after :all do
        @owner.destroy
        @collection.destroy
        @new_collaborator.destroy
        @old_collaborator.destroy
        @new_deed.destroy
        @old_deed.destroy
      end
  
      it "stores the owner as an attribute" do
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        expect(activity.owner).to eq(@owner)
      end
      
      it "retrieves owner collections and sets as an attribute" do
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        expect(activity.collections.first).to eq(@collection)
      end
      
      it "retrieves new owner collaborators and sets as an attribute" do
        @new_collaborator_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          collection_id: @collection.id,
          user_id: @new_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        expect(activity.collaborators.first).to eq(@new_collaborator)
        # Make sure the old collaborator isn't listed
        expect(activity.collaborators.length).to eq(1)
      end
  end

  describe "#has_activity?" do
    before :all do
      @activity_owner = create(:user)
      @activity_collection = create(:collection, owner_user_id: @activity_owner.id)
      @activity_work = create(:work, collection_id: @activity_collection.id)
      @activity_page = create(:page, work_id: @activity_work.id)
      @activity_collaborator = create(:user)
    end

    after :each do
      @activity_deed&.destroy
    end

    after :all do
      @activity_page.destroy
      @activity_work.destroy
      @activity_collection.destroy
      @activity_collaborator.destroy
      @activity_owner.destroy
    end

    context "when there are new collaborators" do
      it "returns true" do
        @activity_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          collection_id: @activity_collection.id,
          user_id: @activity_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@activity_owner)
        expect(activity.has_activity?).to be true
      end
    end

    context "when there are new comments" do
      it "returns true" do
        @activity_deed = create(:deed, {
          deed_type: DeedType::NOTE_ADDED,
          collection_id: @activity_collection.id,
          page_id: @activity_page.id,
          work_id: @activity_work.id,
          user_id: @activity_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@activity_owner)
        expect(activity.has_activity?).to be true
      end
    end

    context "when there is new activity (non-comment deeds)" do
      it "returns true" do
        @activity_deed = create(:deed, {
          deed_type: DeedType::PAGE_TRANSCRIPTION,
          collection_id: @activity_collection.id,
          page_id: @activity_page.id,
          work_id: @activity_work.id,
          user_id: @activity_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@activity_owner)
        expect(activity.has_activity?).to be true
      end
    end

    context "when there is no new activity" do
      it "returns false" do
        activity = AdminMailer::OwnerCollectionActivity.build(@activity_owner)
        expect(activity.has_activity?).to be false
      end
    end

    context "when there are old deeds but no recent activity" do
      it "returns false" do
        @activity_deed = create(:deed, {
          deed_type: DeedType::PAGE_TRANSCRIPTION,
          collection_id: @activity_collection.id,
          page_id: @activity_page.id,
          work_id: @activity_work.id,
          user_id: @activity_collaborator.id,
          created_at: 2.days.ago
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@activity_owner)
        expect(activity.has_activity?).to be false
      end
    end
  end
end