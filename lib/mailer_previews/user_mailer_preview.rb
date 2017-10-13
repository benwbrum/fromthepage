class UserMailerPreview < ActionMailer::Preview

  def upload_finished
    UserMailer.upload_finished(DocumentUpload.last)
  end

  def new_owner
    UserMailer.new_owner(User.last, "testing")
  end

end
