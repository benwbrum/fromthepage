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
    mail to: @user.email, subject: "You've been added to #{@collection.title}"
  end

  def work_collaborator(user, work)
    @user = user
    @work = work
    mail to: @user.email, subject: "You've been added to #{@work.title}"
  end

  def nightly_user_activity(user)
    @user = user
    @user_activity = Activity.build(user)

    if @user_activity.has_activity
      mail to: @user.email, subject: "New FromThePage Activity"
    end
  end

  private

  def add_inline_attachments!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end


  class Activity
    attr_accessor :added_works, :active_pages, :active_translations, :active_note_pages, :has_activity

    def initialize(added_works:, active_pages:, active_translations:, active_note_pages:, has_activity:)
      @added_works = added_works
      @active_pages = active_pages
      @active_translations = active_translations
      @active_note_pages = active_note_pages
      @has_activity = has_activity
    end

    class << self
      def build(user)
        #find which pages the user has worked on
        user_page_ids ||= user.deeds.pluck(:page_id).uniq.compact

        active_pages = user_pages_edited_in_past_day(user, user_page_ids)
        active_translations = user_pages_translated_in_past_day(user, user_page_ids)
        active_note_pages = user_pages_with_notes_added_in_past_day(user, user_page_ids)

        active_items = (active_pages + active_translations + active_note_pages)

        Activity.new(
          {
            added_works: user_works_added_in_past_day(user),
            active_pages: active_pages,
            active_translations: active_translations,
            active_note_pages: active_note_pages,
            has_activity: active_items.blank? ? false : true
          }
        )
      end

      private

      def user_pages_edited_in_past_day(user, user_page_ids)
        recently_modified_pages = Page.joins(:deeds).where(deeds: {deed_type: DeedType.edited_and_transcribed_pages}).merge(Deed.past_day).distinct
        #find pages that have been newly edited by someone other than the user (the user is not the last editor)
        recently_modified_pages.where(id: user_page_ids).select {|page| page if page.deeds.where(deed_type: DeedType.edited_and_transcribed_pages).last.user_id != user.id}
      end

      def user_pages_translated_in_past_day(user, user_page_ids)
        recently_edited_translation_pages = Page.joins(:deeds).where(deeds: {deed_type: DeedType.new_and_edited_translations}).merge(Deed.past_day).distinct
        # find translation pages that have been newly edited by someone other than the user
        recently_edited_translation_pages.where(id: user_page_ids).select {|page| page if page.deeds.where(deed_type: DeedType.new_and_edited_translations).last.user_id != user.id}
      end

      def user_pages_with_notes_added_in_past_day(user, user_page_ids)
        pages_with_recent_notes = Page.joins(:deeds).where(deeds: {deed_type: DeedType::NOTE_ADDED}).merge(Deed.past_day).distinct
        # find pages that the user has worked on that has had notes added recently
        pages_with_recent_notes.where(id: user_page_ids).select {|page| page if page.deeds.where(deed_type: DeedType::NOTE_ADDED).last.user_id != user.id}
      end

      def user_works_added_in_past_day(user)
        # collections the user has worked in
        user_collection_ids = user.deeds.pluck(:collection_id).uniq
        # works that have been added to those collections by someone other than the user in the past day
        Work.where(collection_id: user_collection_ids).joins(:deeds).where(deeds: {deed_type: DeedType::WORK_ADDED}).merge(Deed.past_day).where.not(deeds: {user_id: user.id}).distinct
      end
    end #end class << self
  end #end Activity
end
