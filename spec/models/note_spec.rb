require 'spec_helper'

describe Note do
  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end

  describe '#email_users' do
    let(:owner) { create(:unique_user, :owner) }
    let(:transcriber) { create(:unique_user) }

    context 'when work is in a public collection' do
      let(:collection) { create(:collection, owner_user_id: owner.id) }
      let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
      let(:page) { create(:page, work: work) }

      it 'sends an email to a previous note author who can access the work' do
        # transcriber leaves a note
        create(:note, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: transcriber.id)
        transcriber.notification.update!(note_added: true)

        ActionMailer::Base.deliveries.clear

        # owner leaves a reply note - this should trigger email to transcriber
        expect do
          create(:note, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: owner.id)
        end.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(ActionMailer::Base.deliveries.first.to).to include(transcriber.email)
      end
    end

    context 'when work is in a private collection with a private document set' do
      let(:collection) { create(:collection, :private, :docset_enabled, owner_user_id: owner.id) }
      let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
      let(:page) { create(:page, work: work) }
      let(:private_document_set) do
        ds = DocumentSet.create!(
          title: 'Private Set',
          collection: collection,
          owner: owner,
          visibility: :private
        )
        ds.works << work
        ds
      end

      before { private_document_set }

      it 'does not send an email to a transcriber who no longer has access' do
        # transcriber leaves a note when they had access (simulate past access)
        create(:note, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: transcriber.id)
        transcriber.notification.update!(note_added: true)

        ActionMailer::Base.deliveries.clear

        # owner leaves a reply - transcriber should NOT receive email (no access to private set)
        expect do
          create(:note, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: owner.id)
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'when work is in a private collection with a public document set' do
      let(:collection) { create(:collection, :private, :docset_enabled, owner_user_id: owner.id) }
      let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
      let(:page) { create(:page, work: work) }
      let(:public_document_set) do
        ds = DocumentSet.create!(
          title: 'Public Set',
          collection: collection,
          owner: owner,
          visibility: :public
        )
        ds.works << work
        ds
      end

      before { public_document_set }

      it 'sends an email to a previous note author with access via the public document set' do
        # transcriber leaves a note via the public document set
        create(:note, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: transcriber.id)
        transcriber.notification.update!(note_added: true)

        ActionMailer::Base.deliveries.clear

        # owner leaves a reply - transcriber should receive email (has access via public document set)
        expect do
          create(:note, collection_id: collection.id, work_id: work.id, page_id: page.id, user_id: owner.id)
        end.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(ActionMailer::Base.deliveries.first.to).to include(transcriber.email)
        # The email link should use the document set URL (not the private parent collection)
        expect(ActionMailer::Base.deliveries.first.body.encoded).to include(public_document_set.slug)
      end
    end
  end
end
