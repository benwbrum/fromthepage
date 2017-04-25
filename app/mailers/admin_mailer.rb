class AdminMailer < ActionMailer::Base
  include ContributorHelper
  helper ContributorHelper

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

  def email_stats(hours)
    
    #call method from contributors helper
    show_email_stats(hours)
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: "FromThePage activity in the last #{hours} hours."
  end

  def collection_stats_by_owner(owner, start_date, end_date)
    @collections = owner.all_owner_collections.joins(:deeds).where(deeds: {created_at: start_date..end_date})
    @start_date = start_date
    @end_date = end_date
    
    mail from: SENDING_EMAIL_ADDRESS, to: owner.email, subject: "FromThePage collection activity in the last 24 hours"
  end


  private
  def admin_emails
    User.where(:admin => true).to_a.map { |u| u.email }
  end
  
  def add_inline_attachments!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end

end
