require "rails_helper"

RSpec.describe SystemMailer, :type => :mailer do
  describe "new_upload" do
    let(:mail) { SystemMailer.new_upload }

    it "renders the headers" do
      expect(mail.subject).to eq("New upload")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "upload_succeeded" do
    let(:mail) { SystemMailer.upload_succeeded }

    it "renders the headers" do
      expect(mail.subject).to eq("Upload succeeded")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

  describe "new_user" do
    let(:mail) { SystemMailer.new_user }

    it "renders the headers" do
      expect(mail.subject).to eq("New user")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
