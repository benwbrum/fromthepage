class UserMailer < ActionMailer::Base

  default from: SENDING_EMAIL_ADDRESS
  layout "mailer"

  before_filter :add_inline_attachments!

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.upload_finished.subject
  #
  def upload_finished(document_upload)
    @document_upload = document_upload

    mail to: @document_upload.user.email, subject: "Your upload is ready"
  end

  def iiif_collection_import_failed(user_id, collection_id, errors)
    user_email = User.find_by(id: user_id).email
    @collection = Collection.find_by(id: collection_id)
    @errors = errors
    mail to: user_email, subject: "#{@collection.title} - Import Errors"
  end

  def iiif_collection_import_succeeded(user_id, collection_id)
    user_email = User.find_by(id: user_id).email
    @collection = Collection.find_by(id: collection_id)
    mail to: user_email, subject: "#{@collection.title} - Import Complete"
  end


  private
  def add_inline_attachments!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end

end
