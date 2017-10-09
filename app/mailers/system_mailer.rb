class SystemMailer < ActionMailer::Base
  include ContributorHelper

  default from: "FromThePage <support@fromthepage.com>"
  layout "mailer"

  before_filter :add_inline_attachments!

  def config_test(target_email)
    mail from: SENDING_EMAIL_ADDRESS, to: target_email, subject: "Mail config test for FromThePage"
  end


  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.system_mailer.new_upload.subject
  #
  def new_upload(document_upload)
    @document_upload = document_upload
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: "New document upload - #{document_upload.name}"
  end

  def email_stats(hours)
    @hours = hours
    @recent_users = User.where("created_at > ?", Time.now - hours.to_i.hours)
    @recent_deeds = Deed.where("created_at > ?", Time.now - hours.to_i.hours)
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: "FromThePage had #{@recent_users.count} new users in last #{hours} hours."
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.system_mailer.upload_succeeded.subject
  #
  def upload_succeeded(document_upload)
    @document_upload = document_upload
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: "Upload succeeded - #{document_upload.name}"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.system_mailer.new_user.subject
  #
  def new_user
    @greeting = "Hi"
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: "New FromThePage user "
  end

  def page_save_failed(message, ex)
    @message = message
    @ex = ex
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: "Page save failed"
  end

  private
  def admin_emails
    User.where(:admin => true).to_a.map { |u| u.email }
  end
  
  def add_inline_attachments!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end

end
