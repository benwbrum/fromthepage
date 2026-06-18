require 'spec_helper'

RSpec.describe AdminMailer, type: :mailer do
  describe 'nightly owner email' do
    before :all do
      @owner = create(:user)
      @collection = create(:collection, owner_user_id: @owner.id)
      @work = create(:work, collection_id: @collection.id, owner_user_id: @owner.id)
      @page = create(:page, work_id: @work.id)
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
      @page.destroy
      @work.destroy
      @owner.destroy
      @collection.destroy
      @new_collaborator.destroy
      @old_collaborator.destroy
      @old_deed.destroy
    end

    after :each do
      @suspicious_behavior&.destroy
      @suspicious_behavior = nil
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
        expect(mail.html_part.body.decoded).not_to match("You have new collaborators!")
      end
      it "doesn't show old activity" do
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.html_part.body.decoded).not_to match("Other Recent Activity in Your Collections")
      end
      it "shows new collaborators' email" do
        @new_collaborator_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          collection_id: @collection.id,
          user_id: @new_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver

        expect(mail.html_part.body.decoded).to match("You have new collaborators!")
        expect(mail.html_part.body.decoded).to match(@new_collaborator.email)
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

        expect(mail.html_part.body.decoded).to match("Comments from Your Collaborators")
        @new_comment.destroy
      end
      it "doesn't show comments when there aren't any" do
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.html_part.body.decoded).not_to match("Comments from Your Collaborators")
      end
      it "shows suspicious behavior details and links" do
        @suspicious_behavior = create(:suspicious_behavior, {
          collection_id: @collection.id,
          page_id: @page.id,
          user_id: @old_collaborator.id,
          resolved_by_user_id: @owner.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver

        expect(mail.html_part.body.decoded).to match("Suspicious Behaviors")
        expect(mail.html_part.body.decoded).to match("View collection suspicious behaviors")
        expect(mail.html_part.body.decoded).to match(@page.title)
        expect(mail.html_part.body.decoded).to match(collection_suspicious_behaviors_url(@owner, @collection, only_path: false))
        expect(mail.html_part.body.decoded).to match(collection_display_page_url(@owner, @collection, @page.work_id, @page, only_path: false))
      end
      it "shows suspicious behaviors when they are the only recent activity" do
        @suspicious_behavior = create(:suspicious_behavior, {
          collection_id: @collection.id,
          page_id: @page.id,
          user_id: @old_collaborator.id,
          resolved_by_user_id: @owner.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver

        expect(mail.html_part.body.decoded).to match("Suspicious Behaviors")
        expect(mail.html_part.body.decoded).not_to match("Other Recent Activity in Your Collections")
      end
      it "doesn't show suspicious behaviors when there aren't any" do
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.html_part.body.decoded).not_to match("Suspicious Behaviors")
      end
      it "shows new activity collection title" do
        @new_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          collection_id: @collection.id,
          user_id: @old_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.html_part.body.decoded).to match(@collection.title)
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
        expect(mail.html_part.body.decoded).to match(@old_collaborator.display_name)
        @new_deed.destroy
      end
      it "doesn't show language hashes" do
        @new_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          collection_id: @collection.id,
          user_id: @old_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.html_part.body.decoded).not_to match('{"en":')
        @new_deed.destroy
      end
      it "doesn't show other activity if there isn't any" do
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.html_part.body.decoded).not_to match("Other Recent Activity in Your Collections")
      end
      it "doesn't show other activity if is only comments" do
        @new_comment = create(:deed, {
          deed_type: DeedType::NOTE_ADDED,
          collection_id: @collection.id,
          user_id: @old_collaborator.id
        })
        activity = AdminMailer::OwnerCollectionActivity.build(@owner)
        mail = AdminMailer.collection_stats_by_owner(activity).deliver
        expect(mail.html_part.body.decoded).not_to match("Other Recent Activity in Your Collections")
      end
    end
  end
end
