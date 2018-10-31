require 'spec_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'monthly_owner_wrapup' do
    context "inside the mailer email" do
      before :all do
       user = build_stubbed(:user)
       @qty = 2
       @wrapup = build(:statistic_wrapup, owner: user )
      end

      it 'renders the subject' do
        mail = UserMailer.monthly_owner_wrapup(@wrapup).deliver
        expect(mail.subject).to eq('FromThePage Monthly Wrapup')
      end

      it 'renders the receiver email' do
        mail = UserMailer.monthly_owner_wrapup(@wrapup).deliver
        expect(mail.to).to eq([@wrapup.owner.email])
      end

      it 'renders the sender email' do
        mail = UserMailer.monthly_owner_wrapup(@wrapup).deliver
        expect(mail.from).to eq([SENDING_EMAIL_ADDRESS])
      end

      it 'renders display_name' do
        mail = UserMailer.monthly_owner_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match(@wrapup.owner.display_name)
      end

      it 'renders a link to the summary tab' do
        mail = UserMailer.monthly_owner_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match(summary_url(@wrapup.owner))
      end

      it 'renders counts for all of the page stats' do
        mail = UserMailer.monthly_owner_wrapup(@wrapup).deliver

        expect(mail.body.encoded).to match("#{@qty} Pages")
        expect(mail.body.encoded).to match("#{@qty} Pages Transcribed")
        expect(mail.body.encoded).to match("#{@qty} Pages Edited")
        expect(mail.body.encoded).to match("#{@qty} Pages Translated")
        expect(mail.body.encoded).to match("#{@qty} OCR Corrections")
      end

      it 'renders counts for works stats' do
        mail = UserMailer.monthly_owner_wrapup(@wrapup).deliver

        expect(mail.body.encoded).to match("#{@qty} Total Works")
        expect(mail.body.encoded).to match("#{@qty} Completed Works")
      end

      it 'renders counts for contributor stats' do
        mail = UserMailer.monthly_owner_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match("#{@qty} Contributor")
      end

      it 'renders counts for ocr stats' do
        mail = UserMailer.monthly_owner_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match("#{@qty} OCR Corrections")
      end

      it 'renders counts for subject stats' do
        allow(@wrapup).to receive(:subjects_enabled?).and_return(true)
        mail = UserMailer.monthly_owner_wrapup(@wrapup).deliver

        expect(mail.body.encoded).to match("#{@qty} Subjects")
        expect(mail.body.encoded).to match("#{@qty} References")
        expect(mail.body.encoded).to match("#{@qty} Pages Indexed")
      end

      it 'renders a list of contributor emails' do
        mail = UserMailer.monthly_owner_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match(@wrapup.contributor_emails)
      end

    end # inside the mailer
  end # monthly_owner_wrapup



  describe 'project_wrapup' do
    context "inside the mailer email" do
      before :all do
        user = build_stubbed(:user)
        collection = build_stubbed(:collection, owner_user_id: user.id)
        @qty = 2
        @wrapup = build(:statistic_wrapup, owner: user, collection: collection )
      end

      it 'renders the subject' do
        mail = UserMailer.project_wrapup(@wrapup).deliver
        expect(mail.subject).to eq("#{@wrapup.title} is 100\% Transcribed!")
      end

      it 'renders the receiver email' do
        mail = UserMailer.project_wrapup(@wrapup).deliver
        expect(mail.to).to eq([@wrapup.owner.email])
      end

      it 'renders the sender email' do
        mail = UserMailer.project_wrapup(@wrapup).deliver
        expect(mail.from).to eq([SENDING_EMAIL_ADDRESS])
      end

      it 'renders display_name' do
        mail = UserMailer.project_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match(@wrapup.owner.display_name)
      end

      it 'renders a link to export the project' do
        mail = UserMailer.project_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match(collection_export_url(@wrapup.owner, @wrapup.collection))
      end

      it 'renders a link to the API Wiki' do
        mail = UserMailer.project_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match(IIIF_API_WIKI_LINK)
      end

      it 'renders counts for all of the page stats' do
        mail = UserMailer.project_wrapup(@wrapup).deliver

        expect(mail.body.encoded).to match("#{@qty} Pages")
        expect(mail.body.encoded).to match("#{@qty} Pages Transcribed")
        expect(mail.body.encoded).to match("#{@qty} Pages Edited")
        expect(mail.body.encoded).to match("#{@qty} Pages Translated")
        expect(mail.body.encoded).to match("#{@qty} OCR Corrections")
      end

      it 'renders counts for works stats' do
        mail = UserMailer.project_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match("#{@qty} Works")
      end

      it 'renders counts for contributor stats' do
        mail = UserMailer.project_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match("#{@qty} Contributor")
      end

      it 'renders counts for ocr stats' do
        mail = UserMailer.project_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match("#{@qty} OCR Corrections")
      end

      it 'renders counts for subject stats' do
        allow(@wrapup).to receive(:subjects_enabled?).and_return(true)
        mail = UserMailer.project_wrapup(@wrapup).deliver

        expect(mail.body.encoded).to match("#{@qty} Subjects")
        expect(mail.body.encoded).to match("#{@qty} References")
        expect(mail.body.encoded).to match("#{@qty} Pages Indexed")
      end

      it 'renders a list of contributor emails' do
        mail = UserMailer.project_wrapup(@wrapup).deliver
        expect(mail.body.encoded).to match(@wrapup.contributor_emails)
      end

    end # inside the mailer
  end # project_wrapup
end
