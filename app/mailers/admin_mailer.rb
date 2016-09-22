class AdminMailer < ActionMailer::Base
  include ContributorHelper

  before_filter :add_inline_attachments!

  default from: "FromThePage <support@fromthepage.com>"
  layout "admin_mailer"
  
  def contributor_stats(collection_id, start_date, end_date)

    new_contributors(collection_id, start_date, end_date)

    mail from: SENDING_EMAIL_ADDRESS, to: 'trishablewis@gmail.com', subject: "New Transcription Info "
    mail 
  end

  private
  def admin_emails
    User.where(:admin => true).to_a.map { |u| u.email }
  end
  
  def add_inline_attachments!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end

end
