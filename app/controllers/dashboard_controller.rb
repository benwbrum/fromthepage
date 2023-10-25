# frozen_string_literal: true
class DashboardController < ApplicationController
  include AddWorkHelper
  include OwnerExporter
  PAGES_PER_SCREEN = 20

  before_action :authorized?,
    only: [:owner, :staging, :startproject, :summary]

  before_action :get_data,
    only: [:owner, :staging, :upload, :new_upload,
           :startproject, :empty_work, :create_work, :summary, :exports]

  before_action :remove_col_id

  def authorized?
    unless user_signed_in? && current_user.owner
      redirect_to dashboard_path
    end
  end

  def dashboard_role
    if user_signed_in?
      if current_user.owner
        redirect_to dashboard_owner_path
      elsif current_user.guest?
        redirect_to guest_dashboard_path
      else
        redirect_to dashboard_watchlist_path
      end
    else
      redirect_to guest_dashboard_path
    end
  end


  # Public Dashboard - list of all collections
  def index
    if Collection.all.count > 1000
      redirect_to landing_page_path
    else
      redirect_to collections_list_path
    end
  end

  def collections_list(private_only=false)
    if private_only
      cds = []
    else
      public_collections   = Collection.unrestricted.includes(:owner, next_untranscribed_page: :work)
      public_document_sets = DocumentSet.unrestricted.includes(:owner, next_untranscribed_page: :work)

      cds = public_collections + public_document_sets
    end
    if user_signed_in?
      cds |= current_user.all_owner_collections.includes(:owner, next_untranscribed_page: :work)
      cds |= current_user.document_sets.includes(:owner, next_untranscribed_page: :work)

      cds |= current_user.collection_collaborations.includes(:owner, next_untranscribed_page: :work)
      cds |= current_user.document_set_collaborations.includes(:owner, next_untranscribed_page: :work)
    end
    @collections_and_document_sets = cds.sort { |a,b| a.slug <=> b.slug }
  end

  # Owner Dashboard - start project
  # other methods in AddWorkHelper
  def startproject
    @work = Work.new
    @work.collection = @collection
    @document_upload = DocumentUpload.new
    @document_upload.collection = @collection
    @sc_collections = ScCollection.all
  end

  # Owner Dashboard - list of works
  def owner
    collections = current_user.all_owner_collections
    @active_collections = @collections.select { |c| c.active? }
    @inactive_collections = @collections.select { |c| !c.active? }
    # Needs to be active collections first, then inactive collections
    @collections = @active_collections + @inactive_collections
  end

  # Owner Summary Statistics - statistics for all owned collections
  def summary
    start_d = params[:start_date]
    end_d = params[:end_date]

    max_date = 1.day.ago

    # Give a week fo data if there are no dates
    @start_date = start_d&.to_datetime&.beginning_of_day || 1.week.ago.beginning_of_day
    @end_date = end_d&.to_datetime&.end_of_day || max_date
    @end_date = max_date if max_date < @end_date

    @statistics_object = current_user
    @subjects_disabled = @statistics_object.collections.all?(&:subjects_disabled)

    # Stats
    owner_collections = current_user.all_owner_collections.map{ |c| c.id }
    contributor_ids_for_dates = AhoyActivitySummary
        .where(collection_id: owner_collections)
        .where('date BETWEEN ? AND ?', @start_date, @end_date).distinct.pluck(:user_id)

    @contributors = User.where(id: contributor_ids_for_dates).order(:display_name)

    @activity = AhoyActivitySummary
        .where(collection_id: owner_collections)
        .where('date BETWEEN ? AND ?', @start_date, @end_date)
        .group(:user_id)
        .sum(:minutes)
  end

  # Collaborator Dashboard - watchlist
  def watchlist
    works = Work.joins(:deeds).where(deeds: { user_id: current_user.id }).distinct
    recent_collections = Collection.joins(:deeds).where(deeds: { user_id: current_user.id }).where('deeds.created_at > ?', Time.now-2.days).distinct.order_by_recent_activity.limit(5)
    collections = Collection.where(id: current_user.ahoy_activity_summaries.pluck(:collection_id)).distinct.order_by_recent_activity.limit(5)
    document_sets = DocumentSet.joins(works: :deeds).where(works: { id: works.ids }).order('deeds.created_at DESC').distinct.limit(5)
    collections_list(true) # assigns @collections_and_document_sets for private collections only
    @collections = (collections + recent_collections + document_sets).uniq.sort { |a, b| a.title <=> b.title }.take(5)
  end


  def exports
    @bulk_exports = current_user.bulk_exports.order('id DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
  end


  # Collaborator Dashboard - activity
  def editor
    @user = current_user
  end

  # Guest Dashboard - activity
  def guest
    @collections = Collection.order_by_recent_activity.unrestricted.distinct.limit(5)
  end

  def landing_page
    # Get random Collections and DocSets from paying users
    @owners = User.findaproject_owners.order(:display_name).joins(:collections).left_outer_joins(:document_sets).includes(:collections)

    # Sampled Randomly down to 8 items for Carousel
    docsets = DocumentSet.carousel.includes(:owner).where(owner_user_id: @owners.ids.uniq).sample(5)
    colls = Collection.carousel.includes(:owner).where(owner_user_id: @owners.ids.uniq).sample(5)
    @collections = (docsets + colls).sample(8)
  end

  private

  def document_upload_params
    params.require(:document_upload).permit(:document_upload, :file, :preserve_titles, :ocr, :collection_id)
  end

  def work_params
    params.require(:work).permit(:title, :description, :collection_id)
  end
end
