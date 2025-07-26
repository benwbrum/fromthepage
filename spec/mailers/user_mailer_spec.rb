require 'spec_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'upload_no_images_warning' do
    let(:user) { build_stubbed(:user) }
    let(:collection) { build_stubbed(:collection) }
    let(:document_upload) { build_stubbed(:document_upload, user: user, collection: collection) }

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
      allow(document_upload).to receive(:name).and_return('test.zip')
      mail = UserMailer.upload_no_images_warning(document_upload)
      expect(mail.body.encoded).to include('test.zip')
    end

    it 'includes supported formats information' do
      mail = UserMailer.upload_no_images_warning(document_upload)
      expect(mail.body.encoded).to include('JPG, JPEG, PNG')
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
end
