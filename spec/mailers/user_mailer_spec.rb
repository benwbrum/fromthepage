require 'spec_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'upload_no_images_warning' do
    let(:user) { create(:user) }
    let(:collection) { create(:collection, owner_user_id: user.id) }
    let(:document_upload) { create(:document_upload, user: user, collection: collection) }

    after do
      # Clean up created records
      document_upload.destroy
      collection.destroy
      user.destroy
    end

    it 'renders the subject' do
      mail = UserMailer.upload_no_images_warning(document_upload)
      expect(mail.subject).to eq('Upload processing complete - no images found')
    end

    it 'renders the receiver email' do
      mail = UserMailer.upload_no_images_warning(document_upload)
      expect(mail.to).to eq([ user.email ])
    end

    it 'renders the sender email' do
      mail = UserMailer.upload_no_images_warning(document_upload)
      expect(mail.from).to eq([ 'support@fromthepage.com' ])
    end

    it 'includes the filename in the message' do
      mail = UserMailer.upload_no_images_warning(document_upload)
      expect(mail.body.encoded).to include(document_upload.name)
    end

    it 'includes supported formats information' do
      mail = UserMailer.upload_no_images_warning(document_upload)
      # Test for the actual translated content that should be rendered
      expect(mail.body.encoded).to include('JPG, JPEG, PNG')
      expect(mail.body.encoded).to include('no supported image files were found')
    end
  end

  describe 'nightly_user_activity' do
    context "inside the mailer email" do
      it 'renders the subject' do
        user = build_stubbed(:user)
        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)
        mail = UserMailer.nightly_user_activity(user_activity).deliver

        expect(mail.subject).to eq('New FromThePage Activity')
      end

      it 'renders the receiver email' do
        user = build_stubbed(:user)
        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)

        mail = UserMailer.nightly_user_activity(user_activity).deliver

        expect(mail.to).to eq([ user.email ])
      end

      it 'renders the sender email' do
        user = build_stubbed(:user)
        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)

        mail = UserMailer.nightly_user_activity(user_activity).deliver

        expect(mail.from).to eq([ 'support@fromthepage.com' ])
      end

      it 'renders display_name' do
        user = build_stubbed(:user)
        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)

        mail = UserMailer.nightly_user_activity(user_activity).deliver

        expect(mail.body.encoded).to match(user.display_name)
      end

      it 'displays New Works in email' do
        new_works_heading = "New Works"
        user = create(:user)
        collection = create(:collection, owner_user_id: user.id)
        work = create(:work, collection_id: collection.id, owner_user_id: user.id)

        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)
        allow(user_activity).to receive(:added_works).and_return([ work ])

        mail = UserMailer.nightly_user_activity(user_activity).deliver

        expect(mail.body.encoded).to match(new_works_heading)
        expect(mail.body.encoded).to match(work.title)

        # Tear down factory data
        work.destroy
        collection.destroy
        user.destroy
      end
      it 'displays New Notes in email' do
        new_notes_heading = "New Notes"
        user = create(:user)
        collection = create(:collection, owner_user_id: user.id)
        work = create(:work, collection_id: collection.id)
        page = create(:page, work_id: work.id)

        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)
        allow(user_activity).to receive(:active_note_pages).and_return([ page ])

        mail = UserMailer.nightly_user_activity(user_activity).deliver

        expect(mail.body.encoded).to match(new_notes_heading)
        expect(mail.body.encoded).to match(page.title)

        # Tear down factory data
        page.destroy
        work.destroy
        collection.destroy
        user.destroy
      end
    end
  end

  describe 'metadata refresh finished' do
    context 'inside the mailer email' do
      let(:user) { create(:unique_user, :owner) }
      let(:collection) { create(:collection, owner_user_id: user.id) }
      let(:original_metadata) { [ { label: 'en', value: [ 'Original Metadata' ] } ].to_json }
      let(:at_id) { 'http://example.com/manifest' }
      let(:v3_hash) do
        {
          id: at_id,
          label: { en: [ 'Original Metadata' ] },
          metadata: original_metadata
        }.to_json.to_s
      end

      let(:sc_manifest) { ScManifest.manifest_for_v3_hash(v3_hash) }
      let(:work) { create(:work, collection: collection, sc_manifest: sc_manifest) }
      let(:work_no_manifest) { create(:work, collection: collection) }
      let(:id) { collection.id }
      let(:type) { 'collection' }

      let(:result) { Work::Metadata::Refresh.new(work_ids: [ work.id, work_no_manifest.id ]).call }
      let(:mail) { UserMailer.metadata_refresh_finished(user, result, id, type, result.logs) }

      it 'renders success email' do
        VCR.use_cassette('iiif/refresh_metadata', record: :none) do
          expect(mail.subject).to eq("Metadata refresh for collection:#{id} is finished.")
          expect(mail.to).to eq([ user.email ])
          expect(mail.from).to eq([ 'support@fromthepage.com' ])
          expect(mail.body.encoded).to match(user.display_name)
          expect(mail.body.encoded).to match('Metadata refresh finished successfully.')
          expect(mail.attachments.count).to eq(2)
        end
      end

      context 'failed refresh' do
        VCR.use_cassette('iiif/refresh_metadata_failed', record: :none) do
          it 'renders failed email' do
            expect(mail.subject).to eq("Metadata refresh for collection:#{id} is finished.")
            expect(mail.to).to eq([ user.email ])
            expect(mail.from).to eq([ 'support@fromthepage.com' ])
            expect(mail.body.encoded).to match(user.display_name)
            expect(mail.body.encoded).to match('Metadata refresh finished with errors.')
            expect(mail.attachments.count).to eq(2)
          end
        end
      end
    end
  end
end
