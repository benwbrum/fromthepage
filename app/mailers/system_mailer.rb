class SystemMailer < ActionMailer::Base
  default from: "from@example.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.system_mailer.new_upload.subject
  #
  def new_upload(document_upload)
    @document_upload = document_upload
    mail to: "benwbrum@gmail.com"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.system_mailer.upload_succeeded.subject
  #
  def upload_succeeded
    @greeting = "Hi"

    mail to: "benwbrum@gmail.com"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.system_mailer.new_user.subject
  #
  def new_user
    @greeting = "Hi"

    mail(to: "benwbrum@gmail.com", subject: "New Document Upload")
  end
end
