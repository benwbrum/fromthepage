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

  def new_owner(user, text)
    @owner = user
    @text = text
    mail to: @owner.email, subject: "New FromThePage Owner"
  end

  def added_note(user, note)
    @user = user
    @note = note
    @page = note.page
    mail to: @user.email, subject: "New FromThePage Note"
  end

  def collection_collaborator(user, obj)
    @user = user
    if obj.is_a?(Collection)
      @collection = obj
    else
      @collection = obj
    end
    mail to: @user.email, subject: "New FromThePage Collaborator"
  end

  def work_collaborator(user, work)
    @user = user
    @work = work
    mail to: @user.email, subject: "New FromThePage Collaborator"
  end

  def nightly_user_activity(user, pages=nil, works=nil, note_pages=nil)
    @user = user
    @added_works = works
    @active_pages = pages
    @active_note_pages = note_pages
    mail to: @user.email, subject: "New FromThePage Activity"
  end

  private
  def add_inline_attachments!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end

end
