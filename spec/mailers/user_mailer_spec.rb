require 'spec_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'nightly_user_activity' do

    context "inside the mailer email" do
      it 'renders the subject' do
        user = build_stubbed(:user)
        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)
        mail = UserMailer.nightly_user_activity(user_activity: user_activity).deliver

        expect(mail.subject).to eq('New FromThePage Activity')
      end

      it 'renders the receiver email' do
        user = build_stubbed(:user)
        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)

        mail = UserMailer.nightly_user_activity(user_activity: user_activity).deliver

        expect(mail.to).to eq([user.email])
      end

      it 'renders the sender email' do
        user = build_stubbed(:user)
        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)

        mail = UserMailer.nightly_user_activity(user_activity: user_activity).deliver

        expect(mail.from).to eq(['support@fromthepage.com'])
      end

      it 'renders display_name' do
        user = build_stubbed(:user)
        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)

        mail = UserMailer.nightly_user_activity(user_activity: user_activity).deliver

        expect(mail.body.encoded).to match(user.display_name)
      end

      it 'displays Edited Pages in email' do
        edited_page_heading = "Edited Pages"
        user = create(:user)
        collection = create(:collection, owner_user_id: user.id)
        work = create(:work, collection_id: collection.id)
        page = create(:page, work_id: work.id)

        user_activity = UserMailer::Activity.build(user)
        allow(user_activity).to receive(:has_contributions?).and_return(true)
        allow(user_activity).to receive(:active_pages).and_return([page])

        mail = UserMailer.nightly_user_activity(user_activity: user_activity).deliver

        expect(mail.body.encoded).to match(edited_page_heading)
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
