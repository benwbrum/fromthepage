require 'spec_helper'

RSpec.describe AdminMailer, type: :mailer do
  describe 'email stats' do
    let!(:trial_owner) { create(:user, :owner, account_type: 'Trial', created_at: 2.hours.ago) }
    let!(:older_trial_owner) { create(:user, :owner, account_type: 'Trial', created_at: 2.days.ago) }
    let!(:failed_bulk_export) { create(:bulk_export, :error, collection_id: collection.id, user_id: admin.id, updated_at: 2.hours.ago) }
    let!(:older_failed_bulk_export) { create(:bulk_export, :error, collection_id: collection.id, user_id: admin.id, updated_at: 2.days.ago) }
    let!(:failed_ai_transcription) { create(:document_upload, collection: collection, user: admin, ocr: true, status: :error, updated_at: 2.hours.ago) }
    let!(:non_ocr_failed_upload) { create(:document_upload, collection: collection, user: admin, ocr: false, status: :error, updated_at: 2.hours.ago) }
    let!(:successful_ocr_upload) { create(:document_upload, collection: collection, user: admin, ocr: true, status: :finished, updated_at: 2.hours.ago) }
    let!(:admin) { create(:admin) }
    let!(:collection) { create(:collection, owner_user_id: admin.id) }

    it 'includes recent trial users and recent failure log links' do
      mail = AdminMailer.email_stats(24).deliver
      body = mail.html_part ? mail.html_part.body.decoded : mail.body.decoded

      expect(body).to include('New Trial Users')
      expect(body).to include(trial_owner.email)
      expect(body).not_to include(older_trial_owner.email)

      expect(body).to include('Failed Bulk Exports')
      expect(body).to include(admin_view_bulk_export_log_url(id: failed_bulk_export.id))
      expect(body).not_to include(admin_view_bulk_export_log_url(id: older_failed_bulk_export.id))

      expect(body).to include('Failed AI Transcriptions')
      expect(body).to include(admin_view_processing_log_url(id: failed_ai_transcription.id))
      expect(body).not_to include(admin_view_processing_log_url(id: non_ocr_failed_upload.id))
      expect(body).not_to include(admin_view_processing_log_url(id: successful_ocr_upload.id))
    end
  end

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

      %i[de fr].each do |locale|
        it "renders suspicious behavior mailer copy in #{locale}" do
          @suspicious_behavior = create(:suspicious_behavior, {
            collection_id: @collection.id,
            page_id: @page.id,
            user_id: @old_collaborator.id,
            resolved_by_user_id: @owner.id
          })

          I18n.with_locale(locale) do
            activity = AdminMailer::OwnerCollectionActivity.build(@owner)
            mail = AdminMailer.collection_stats_by_owner(activity).deliver

            expect(mail.html_part.body.decoded).to include(I18n.t('admin_mailer.collection_stats_by_owner.suspicious_behaviors'))
            expect(mail.html_part.body.decoded).to include(I18n.t('admin_mailer.collection_stats_by_owner.view_collection_suspicious_behaviors'))
            expect(mail.html_part.body.decoded).not_to include('translation missing')
          end
        end
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
