class AdminMailer < ActionMailer::Base
  include ContributorHelper

  before_filter :add_inline_attachments!

  default from: "FromThePage <support@fromthepage.com>"
  layout "admin_mailer"
  
  def contributor_stats(collection_id, start_date, end_date, email)

    new_contributors(collection_id, start_date, end_date)

    mail from: SENDING_EMAIL_ADDRESS, to: email, subject: "New Transcription Information "
  end

  def owner_stats
    owner_expirations
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: "Owner Expiration Information "
  end

  private
  def admin_emails
    User.where(:admin => true).to_a.map { |u| u.email }
  end
  
  def add_inline_attachments!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end

end
