class SystemMailer < ActionMailer::Base

  default from: "FromThePage <from@example.com>"
  layout "mailer"

  before_filter :add_inline_attachments!

  def config_test(target_email)
    mail to: target_email, subject: "Mail config test for FromThePage"
  end


  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.system_mailer.new_upload.subject
  #
  def new_upload(document_upload)
    @document_upload = document_upload
    mail to: admin_emails, subject: "New document upload - #{document_upload.name}"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.system_mailer.upload_succeeded.subject
  #
  def upload_succeeded(document_upload)
    @document_upload = document_upload
    mail to: admin_emails, subject: "Upload succeeded - #{document_upload.name}"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.system_mailer.new_user.subject
  #
  def new_user
    @greeting = "Hi"
    mail to: admin_emails, subject: "New FromThePage user "
  end

  private
  def admin_emails
    User.where(:admin => true).to_a.map { |u| u.email }
  end
  
  def add_inline_attachments!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end

end