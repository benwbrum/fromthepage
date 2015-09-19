class UserMailer < ActionMailer::Base
  default from: "from@example.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.upload_finished.subject
  #
  def upload_finished(document_upload)
    @document_upload = document_upload
    binding.pry

    mail to: @document_upload.user.email
  end
end
