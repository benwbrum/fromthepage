require 'spec_helper'

RSpec.describe AdminMailer, type: :mailer do
  describe 'nightly owner email' do
    before :all do
      @owner = create(:user)
      @collection = create(:collection, owner_user_id: @owner.id)
      @new_collaborator = create(:user)
      @old_collaborator = create(:user)
      @old_deed = create(:deed, {
        deed_type: DeedType::WORK_ADDED,
        collection_id: @collection.id,
        user_id: @old_collaborator.id,
        created_at: 2.days.ago
      })
    end

    after :all do
      @owner.destroy
      @collection.destroy
      @new_collaborator.destroy
      @old_collaborator.destroy
      @old_deed.destroy
    end

    context "email metadata" do
      it "mailer has correct subject" do 
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.subject).to eq('Recent Activity in Your Collections')
      end
      it "mailer has correct recipient" do 
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.to).to eq([@owner.email])
      end
    end
    context "email content" do
      it "doesn't show old collaborators" do
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.body.encoded).not_to match("You have new collaborators")
      end
      it "doesn't show old activity" do
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.body.encoded).not_to match("Other Recent Activity in Your Collections")
      end
      it "shows new collaborators' email" do
        @new_collaborator_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          collection_id: @collection.id,
          user_id: @new_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver

        expect(mail.body.encoded).to match("You have new collaborators")
        expect(mail.body.encoded).to match(@new_collaborator.email)        
        @new_collaborator_deed.destroy
      end
      it "shows new comments" do
        @new_comment = create(:deed, {
          deed_type: DeedType::NOTE_ADDED,
          collection_id: @collection.id,
          user_id: @old_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver

        expect(mail.body.encoded).to match("Comments from Your Collaborators")   
        @new_comment.destroy
      end
      it "doesn't show comments when there aren't any" do
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.body.encoded).not_to match("Comments from Your Collaborators")
      end
      it "shows new activity collection title" do
        @new_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          collection_id: @collection.id,
          user_id: @old_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.body.encoded).to match(@collection.title)
        @new_deed.destroy
      end
      it "shows new activity" do
        @new_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          collection_id: @collection.id,
          user_id: @old_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.body.encoded).to match(@old_collaborator.display_name)
        @new_deed.destroy
      end
      it "doesn't show other activity if there isn't any" do
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.body.encoded).not_to match("Other Recent Activity in Your Collections")
      end
      it "doesn't show other activity if is only comments" do
        @new_comment = create(:deed, {
          deed_type: DeedType::NOTE_ADDED,
          collection_id: @collection.id,
          user_id: @old_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.body.encoded).not_to match("Other Recent Activity in Your Collections")
      end
    end
  end
end