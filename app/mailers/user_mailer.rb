class UserMailer < ActionMailer::Base
  include UserHelper
  include ContributorHelper

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

  def monthly_owner_wrapup(wrapup_info)
    @wrapup = wrapup_info
    mail to: @wrapup.owner.email, subject: "FromThePage Monthly Wrapup"
  end

  def project_wrapup(wrapup_info)
    #set the collection - are document sets relevant?
    @wrapup = wrapup_info
    mail to: @wrapup.owner.email, subject: "#{@wrapup.title} is 100\% Transcribed!"
  end

  private
  def add_inline_attachments!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end

  class StatisticWrapup
    attr_accessor :owner, :collection, :title, :contributor_emails, :work_count, :completed_work_count, :page_count, :comment_count, :contributor_count, :transcription_count, :edit_count, :translation_count, :ocr_count, :subject_count, :mention_count, :index_count

    def initialize(owner:, collection:, title:, contributor_emails:, work_count:, completed_work_count:, page_count:, comment_count:, contributor_count:, transcription_count:, edit_count:, translation_count:, ocr_count:, subject_count:, mention_count:, index_count: )
      @owner = owner
      @collection = collection
      @title = title
      @contributor_emails = contributor_emails
      @contributor_count = contributor_count
      @work_count = work_count
      @completed_work_count = completed_work_count
      @page_count = page_count
      @comment_count = comment_count
      @transcription_count = transcription_count
      @edit_count = edit_count
      @translation_count = translation_count
      @ocr_count = ocr_count
      @subject_count = subject_count
      @mention_count = mention_count
      @index_count = index_count
    end

    class << self
      def build(object:, start_date: nil, end_date: nil)
        StatisticWrapup.new(
          owner: set_owner(object),
          collection: set_collection(object),
          title: set_title(object),
          contributor_emails: contributor_email_list(object),
          contributor_count: object.contributor_count(start_date, end_date),
          work_count: object.work_count,
          completed_work_count: set_completed_work_count(object),
          page_count: object.page_count,
          comment_count: object.comment_count,
          transcription_count: object.transcription_count(start_date, end_date),
          edit_count: object.edit_count(start_date, end_date),
          translation_count: object.translation_count(start_date, end_date),
          ocr_count: object.ocr_count(start_date, end_date),
          subject_count: object.subject_count(start_date, end_date),
          mention_count: object.mention_count(start_date, end_date),
          index_count: object.index_count(start_date, end_date)
        )
      end

      private

      def contributor_email_list(object)
        object.contributors.map { |contributor| "#{contributor.display_name} <#{contributor.email}>"}.join(', ')
      end

      def set_owner(object)
        object.class == User ? object : object.owner
      end

      def set_collection(object)
        object.class == Collection ? object : nil
      end

      def set_title(object)
        object.class == Collection ? object.title : nil
      end

      def set_completed_work_count(object)
        object.class == User ? object.completed_work_count : nil
      end
    end

    def translations?
      translation_count != 0
    end

    def ocr_corrections?
      ocr_count != 0
    end

    def subjects_enabled?
      !owner.subjects_disabled
    end
  end

end
