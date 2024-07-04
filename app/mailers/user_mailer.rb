class UserMailer < ActionMailer::Base

  include Rails.application.routes.url_helpers
  default from: SENDING_EMAIL_ADDRESS
  layout 'mailer'

  before_action :add_inline_attachments!

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.upload_finished.subject
  #
  def upload_finished(document_upload)
    @document_upload = document_upload

    mail to: @document_upload.user.email, subject: 'Your upload is ready'
  end

  def bulk_export_finished(bulk_export)
    @bulk_export = bulk_export

    mail to: @bulk_export.user.email, subject: 'Your export is ready'
  end

  def new_owner(user, text)
    @owner = user
    @text = text
    mail to: @owner.email, subject: 'New FromThePage Owner'
  end

  def added_note(user, note)
    @user = user
    @note = note
    @page = note.page
    mail to: @user.email, subject: 'New FromThePage Note', reply_to: @note.collection.owner.email
  end

  def collection_reviewer(user, obj)
    @user = user
    @collection = obj
    mail to: @user.email, subject: "You've been added as a reviewer on #{@collection.title}", reply_to: @collection.owner.email
  end

  def collection_collaborator(user, obj)
    @user = user
    if obj.is_a?(Collection)
      @collection = obj
    else
      @collection = obj
    end
    mail to: @user.email, subject: "You've been added to #{@collection.title}", reply_to: @collection.owner.email
  end

  def work_collaborator(user, work)
    @user = user
    @work = work
    mail to: @user.email, subject: "You've been added to #{@work.title}", reply_to: @work.collection.owner.email
  end

  def nightly_user_activity(user_activity)
    @user_activity = user_activity
    mail to: @user_activity.user.email, subject: 'New FromThePage Activity'
  end

  def new_mobile_user(user, obj)
    @user = user
    @collection = obj
    mail to: @user.email, subject: "#{@collection.owner.display_name}'s #{@collection.title} Collection"
  end

  private

  def add_inline_attachments!
    attachments.inline['logo.png'] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end

  class Activity

    attr_accessor :user, :added_works, :active_note_pages

    def initialize(user:, added_works:, active_note_pages:)
      @user = user
      @added_works = added_works
      @active_note_pages = active_note_pages
    end

    class << self

      def build(user)
        # Find which pages the user has worked on
        user_page_ids ||= user.deeds.pluck(:page_id).uniq.compact

        Activity.new(
          user:,
          added_works: works_added_to_users_collection_in_past_day(user),
          active_note_pages: user_pages_with_notes_added_in_past_day(user, user_page_ids)
        )
      end

      private

      def user_pages_with_notes_added_in_past_day(user, user_page_ids)
        pages_with_recent_notes = Page.joins(:deeds).
          where(deeds: { deed_type: DeedType::NOTE_ADDED }).
          merge(Deed.past_day).distinct.
          where.not(deeds: { user_id: user.id })

        pages_with_recent_notes.where(id: user_page_ids).select do |page|
          last_note = page.deeds.where(deed_type: DeedType::NOTE_ADDED).last
          last_note.present? && last_note.user_id != user.id &&
            page.work.access_object(user) && page.work.user_can_transcribe?(user)
        end
      end

      def works_added_to_users_collection_in_past_day(user)
        # collections the user has worked in
        user_collection_ids = user.deeds.pluck(:collection_id).uniq
        # works that have been added to those collections by someone other than the user in the past day
        works = Work.where(collection_id: user_collection_ids).joins(:deeds).
          where(deeds: { deed_type: DeedType::WORK_ADDED }).
          merge(Deed.past_day).
          where.not(deeds: { user_id: user.id }).
          distinct

        works.select { |work| work.access_object(user) && work.user_can_transcribe?(user) }
      end

    end

    def has_contributions?
      (
        @added_works +
        @active_note_pages
      ).any?
    end

  end

end
