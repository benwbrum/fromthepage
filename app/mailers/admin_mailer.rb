class AdminMailer < ActionMailer::Base
  include ContributorHelper
  helper ContributorHelper

  before_filter :add_inline_attachments!

  default from: "FromThePage <support@fromthepage.com>"
  layout "admin_mailer"
  
  def contributor_stats(collection_id, start_date, end_date, email)

    new_contributors(collection_id, start_date, end_date)

    mail from: SENDING_EMAIL_ADDRESS, to: email, subject: "New Transcription Information "
  end

  def owner_stats
    owner_expirations
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: "Owner Expiration Information "
  end

  def email_stats(hours)
    
    #call method from contributors helper
    show_email_stats(hours)
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: "FromThePage activity in the last #{hours} hours."
  end

  def collection_stats_by_owner(activity)
    @activity = activity
    mail from: SENDING_EMAIL_ADDRESS, to: @activity.owner.email, subject: "Recent Activity in Your Collections"
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

  class OwnerCollectionActivity
    attr_accessor :owner, :collections, :collaborators, :since, :comments, :activity
    
    def initialize(owner, activity_since)
      @owner = owner
      @since = activity_since
      @collections = owner.all_owner_collections_updated_since(activity_since)
      @collaborators = owner.new_collaborators_since(activity_since)
      @comments = Deed
        .where(collection: @collections)
        .where('created_at > ?', activity_since)
        .where(deed_type: DeedType::NOTE_ADDED)
      @activity = Deed.includes(:collection)
        .where(collection: @collections)
        .where('created_at > ?', activity_since)
        .where.not(deed_type: DeedType::NOTE_ADDED)
        .group_by{ |d| d.collection.title }
    end
    
    class << self
      def build(owner, activity_since=1.day.ago)
        AdminMailer::OwnerCollectionActivity.new(owner, activity_since)
      end
    end
  end
  private
  def admin_emails
    User.where(:admin => true).to_a.map { |u| u.email }
  end
  
  def add_inline_attachments!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end
end
