class UserMailerPreview < ActionMailer::Preview

  def upload_finished
    UserMailer.upload_finished(DocumentUpload.last)
  end

end
