class UserMailer < ActionMailer::Base
  include UserHelper
  helper ContributorHelper

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
    mail to: @user.email, subject: "You've been added to #{@collection.title}"
  end

  def work_collaborator(user, work)
    @user = user
    @work = work
    mail to: @user.email, subject: "You've been added to #{@work.title}"
  end

  def nightly_user_activity(user)
    @user = user
    user_activity(@user)
    if @active_user
      mail to: @user.email, subject: "New FromThePage Activity"
    end
  end

  def monthly_owner_wrapup(owner)
    @owner = owner
    #find all collections with activity in the last month and/or not 100% transcribed?  Those aren't totally related things.
    @collections = @owner.all_owner_collections.where.not(pct_completed: 100)
    unless @collections.blank?
      mail to: @owner.email, subject: "FromThePage Monthly Wrapup"
    end
  end

  def project_complete(project)
    #set the collection - are document sets relevant?
    @collection = Collection.find_by(slug: project.slug)
    @owner = @collection.owner

    mail to: @owner.email, subject: "#{@collection.title} Project Is 100\% Transcribed!"
  end

  private
  def add_inline_attachments!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end

end
