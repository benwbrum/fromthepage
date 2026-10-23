require 'spec_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'added_note' do
    let(:owner) { create(:unique_user, :owner) }
    let(:transcriber) { create(:unique_user) }
    let(:collection) { create(:collection, owner_user_id: owner.id) }
    let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
    let(:page) { create(:page, work: work) }
    let(:note) { create(:note, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: owner.id) }

    after do
      note.destroy
      page.destroy
      work.destroy
      collection.destroy
      transcriber.destroy
      owner.destroy
    end

    context 'with default collection (parent collection)' do
      it 'renders the subject' do
        mail = UserMailer.added_note(transcriber, note)
        expect(mail.subject).to eq('New FromThePage Note')
      end

      it 'renders the receiver email' do
        mail = UserMailer.added_note(transcriber, note)
        expect(mail.to).to eq([transcriber.email])
      end

      it 'renders the sender email' do
        mail = UserMailer.added_note(transcriber, note)
        expect(mail.from).to eq(['support@fromthepage.com'])
      end

      it 'includes the note body' do
        mail = UserMailer.added_note(transcriber, note)
        expect(mail.body.encoded).to include(note.body)
      end

      it 'links to the parent collection page URL' do
        mail = UserMailer.added_note(transcriber, note)
        expect(mail.body.encoded).to include(collection.slug)
      end
    end

    context 'when access is via a public document set in a private collection' do
      let(:private_collection) { create(:collection, :private, :docset_enabled, owner_user_id: owner.id) }
      let(:work_in_docset) { create(:work, collection: private_collection, owner_user_id: owner.id) }
      let(:page_in_docset) { create(:page, work: work_in_docset) }
      let(:public_document_set) do
        ds = DocumentSet.create!(
          title: 'Public Document Set',
          collection: private_collection,
          owner: owner,
          visibility: :public
        )
        ds.works << work_in_docset
        ds
      end
      let(:note_in_docset) do
        create(:note, collection_id: private_collection.id, work_id: work_in_docset.id,
                      page_id: page_in_docset.id, user_id: owner.id)
      end

      after do
        note_in_docset.destroy
        page_in_docset.destroy
        public_document_set.destroy
        work_in_docset.destroy
        private_collection.destroy
      end

      it 'links to the document set URL (not the private parent collection)' do
        mail = UserMailer.added_note(transcriber, note_in_docset, public_document_set)
        expect(mail.body.encoded).to include(public_document_set.slug)
      end

      it 'uses the document set title in the message' do
        mail = UserMailer.added_note(transcriber, note_in_docset, public_document_set)
        expect(mail.body.encoded).to include(public_document_set.title)
      end

      it 'still uses the parent collection owner for reply_to' do
        mail = UserMailer.added_note(transcriber, note_in_docset, public_document_set)
        expect(mail.reply_to).to eq([private_collection.owner.email])
      end
    end
  end

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
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      mail = UserMailer.upload_no_images_warning(document_upload)
      expect(mail.from).to eq(['support@fromthepage.com'])
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

        expect(mail.to).to eq([user.email])
      end

      it 'renders the sender email' do
        user = build_stubbed(:user)
        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)

        mail = UserMailer.nightly_user_activity(user_activity).deliver

        expect(mail.from).to eq(['support@fromthepage.com'])
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
        allow(user_activity).to receive(:added_works).and_return([work])

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
        allow(user_activity).to receive(:active_note_pages).and_return([page])

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
      let(:original_metadata) { [{ label: 'en', value: ['Original Metadata'] }].to_json }
      let(:at_id) { 'http://example.com/manifest' }
      let(:v3_hash) do
        {
          "@context" => "http://iiif.io/api/presentation/3/context.json",
                "id" => "http://example.com/manifest",
              "type" => "Manifest",
             "label" => {
              "en" => [
                "Original Metadata"
              ]
          },
          "metadata" => [
              {
                "label" => {
                  "en" => [
                     "Origin"
                   ]
                 },
                 "value" => {
                   "en" => [
                      "Test Data"
                   ]
                 }
              }
          ],
           "items" => []
        }.to_json.to_s
      end

      let(:sc_manifest) { ScManifest.manifest_for_v3_hash(v3_hash) }
      let(:work) { create(:work, collection: collection, sc_manifest: sc_manifest) }
      let(:work_no_manifest) { create(:work, collection: collection) }
      let(:id) { collection.id }
      let(:type) { 'collection' }

      let(:result) { Work::Metadata::Refresh.new(work_ids: [work.id, work_no_manifest.id]).call }
      let(:mail) { UserMailer.metadata_refresh_finished(user, result, id, type, result.logs) }

      it 'renders success email' do
        VCR.use_cassette('iiif/refresh_metadata', record: :new_episodes) do
          expect(mail.subject).to eq("Metadata refresh for collection:#{id} is finished.")
          expect(mail.to).to eq([user.email])
          expect(mail.from).to eq(['support@fromthepage.com'])
          expect(mail.body.encoded).to match(user.display_name)
          expect(mail.body.encoded).to match('Metadata refresh finished successfully.')
          expect(mail.attachments.count).to eq(2)
        end
      end

      context 'failed refresh' do
        VCR.use_cassette('iiif/refresh_metadata_failed', record: :new_episodes) do
          it 'renders failed email' do
            expect(mail.subject).to eq("Metadata refresh for collection:#{id} is finished.")
            expect(mail.to).to eq([user.email])
            expect(mail.from).to eq(['support@fromthepage.com'])
            expect(mail.body.encoded).to match(user.display_name)
            expect(mail.body.encoded).to match('Metadata refresh finished with errors.')
            expect(mail.attachments.count).to eq(2)
          end
        end
      end
    end
  end
end
