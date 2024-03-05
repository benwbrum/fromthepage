# frozen_string_literal: true
class DashboardController < ApplicationController
  include AddWorkHelper
  include DashboardHelper
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
      cds |= current_user.all_owner_collections.restricted.includes(:owner, next_untranscribed_page: :work)
      cds |= current_user.document_sets.restricted.includes(:owner, next_untranscribed_page: :work)

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

  def your_hours
    load_user_hours_data
    if @start_date_hours > @end_date_hours
      flash[:error] = "Invalid date range. Please make sure the end date is greater than the start date."
      redirect_to dashboard_your_hours_path
    end
  end
  
  def download_hours_letter
    load_user_hours_data
    @time_duration=params[:time_duration]
    markdown_text = generate_markdown_text

    # write the string to a temp directory
    temp_dir = File.join(Rails.root, 'public', 'printable')
    Dir.mkdir(temp_dir) unless Dir.exist? temp_dir

    time_stub = Time.now.gmtime.iso8601.gsub(/\D/,'')
    temp_dir = File.join(temp_dir, time_stub)
    Dir.mkdir(temp_dir) unless Dir.exist? temp_dir

    file_stub = "letter_#{time_stub}"
    md_file = File.join(temp_dir, "#{file_stub}.md")
    output_file = File.join(temp_dir, "#{file_stub}.pdf")
    
    generate_pdf(md_file, output_file, markdown_text)
  
    send_generated_pdf(output_file)
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
    @collections = (collections + recent_collections + document_sets)
               .uniq
               .sort_by do |collection|
                 if collection.is_a?(Collection)
                   collection.created_on
                 elsif collection.is_a?(DocumentSet)
                   collection.created_at
                 end
               end
               .reverse
               .take(10)
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

  def browse_tag
    @tag = Tag.where(ai_text: params[:ai_text]).first
    @collections = @tag.collections.unrestricted.not_near_complete.has_intro_block.has_picture
  end

  def landing_page
    if params[:search]
      # Get matching Collections and Docsets
      @search_results = Collection.search(params[:search]).unrestricted + DocumentSet.search(params[:search]).unrestricted

      # Get user_ids from the resulting search
      search_user_ids = User.search(params[:search]).pluck(:id) + @search_results.map(&:owner_user_id)

      # Get matching users and users from Collections and DocSets search
      @owners = User.where(id: search_user_ids).where.not(account_type: nil)
    else
      # Get random Collections and DocSets from paying users
      @owners = User.findaproject_owners.order(:display_name).joins(:collections).left_outer_joins(:document_sets).includes(:collections)

      # Sampled Randomly down to 8 items for Carousel
      docsets = DocumentSet.carousel.includes(:owner).where(owner_user_id: @owners.ids.uniq).sample(5)
      colls = Collection.carousel.includes(:owner).where(owner_user_id: @owners.ids.uniq).sample(5)
      @collections = (docsets + colls).sample(8)
    end
  end

  def new_landing_page
    # Get random Collections and DocSets from paying users
    @owners = User.findaproject_owners.order(:display_name).joins(:collections).left_outer_joins(:document_sets).includes(:collections)

    # Sampled Randomly down to 8 items for Carousel
    docsets = DocumentSet.carousel.includes(:owner).where(owner_user_id: @owners.ids.uniq).sample(5)
    colls = Collection.carousel.includes(:owner).where(owner_user_id: @owners.ids.uniq).sample(5)
    @collections = (docsets + colls).sample(8)

    @tag_map = Tag.where(canonical: true).joins(:collections).where("collections.restricted" ==false).group(:ai_text).count

  end


  def collaborator_time_export
    start_date = params[:start_date]
    end_date = params[:end_date]

    start_date = start_date.to_date
    end_date = end_date.to_date

    dates = (start_date..end_date)

    headers = [
      "Username",
      "Email",
    ]

    headers += dates.map{|d| d.strftime("%b %d, %Y")}

    # Get Row Data (Users)
    owner_collections = current_user.all_owner_collections.map{ |c| c.id }


    contributor_ids_for_dates = AhoyActivitySummary
      .where(collection_id: owner_collections)
      .where('date BETWEEN ? AND ?', start_date, end_date).distinct.pluck(:user_id)

    contributors = User.where(id: contributor_ids_for_dates).order(:display_name)

    csv = CSV.generate(:headers => true) do |records|
      records << headers
      contributors.each do |user|
        row = [user.display_name, user.email]

        activity = AhoyActivitySummary
          .where(user_id: user.id)
          .where(collection_id: owner_collections)
          .where('date BETWEEN ? AND ?', start_date, end_date)
          .group(:date)
          .sum(:minutes)
          .transform_keys{ |k| k.to_date }

        user_activity = dates.map{ |d| activity[d.to_date] || 0 }

        row += user_activity

        records << row
      end
    end

    send_data( csv,
              :filename => "#{start_date.strftime('%Y-%m%b-%d')}-#{end_date.strftime('%Y-%m%b-%d')}_activity_summary.csv",
              :type => "application/csv")
  end

  private

  def document_upload_params
    params.require(:document_upload).permit(:document_upload, :file, :preserve_titles, :ocr, :collection_id)
  end

  def work_params
    params.require(:work).permit(:title, :description, :collection_id)
  end

  def load_user_hours_data
    if params['start_date'].present? && params['end_date'].present?
      @start_date_hours = Date.parse(params['start_date'])
      @end_date_hours = Date.parse(params['end_date'])
    else
      @start_date_hours = 7.days.ago.to_date
      @end_date_hours = Date.today
    end
    @time_duration = time_spent_in_date_range(current_user.id, @start_date_hours, @end_date_hours)

    raw = Deed.where(user_id: current_user.id, created_at: [@start_date_hours..@end_date_hours]).pluck(:collection_id, :page_id).uniq
    @collection_id_to_page_count = raw.select{|collection_id, page_id| !page_id.nil? }.map{|collection_id, page_id| collection_id}.tally
    @user_collections = Collection.find(@collection_id_to_page_count.keys).sort{|a,b| a.owner.display_name <=> b.owner.display_name}
  end
  
  def generate_markdown_text
    <<~MARKDOWN
      ![](app/assets/images/logo.png){width=300px style='display: block; margin-left: 300px auto;'}  
      &nbsp; &nbsp;
      \n#{generated_format_date(Time.now.to_date)}\n
      &nbsp; &nbsp;
      \n#{I18n.t('dashboard.hours_letter.to_whom_it_may_concern')}\n
      #{I18n.t('dashboard.hours_letter.certification_text', user_name: current_user.real_name, time_duration: @time_duration, start_date: generated_format_date(@start_date_hours), end_date: generated_format_date(@end_date_hours))}\n
      #{I18n.t('dashboard.hours_letter.worked_on_collections', user_name: current_user.real_name)}\n
      #{I18n.t('dashboard.hours_letter.institutions_header')}
      #{I18n.t('dashboard.hours_letter.institutions_separator')}
      #{generate_collection_rows(@user_collections)}
      #{I18n.t('dashboard.hours_letter.volunteer_text', user_display_name: current_user.display_name)}\n
      |
      #{I18n.t('dashboard.hours_letter.regards_text')}\n
      | 
      | Sara Brumfield
      | Partner, FromThePage
    MARKDOWN
  end
  
  def generate_collection_rows(user_collections)
    user_collections.map do |collection|
      "| #{collection.owner.display_name} | #{collection.title} | #{@collection_id_to_page_count[collection.id]} |"
    end.join("\n")
  end

  def generated_format_date(date)
    formatted_date = date.strftime("%B %d, %Y")
  end
  
  def generate_pdf(input_path, output_path, markdown_text)
    File.write(input_path, markdown_text)
  
    system("pandoc #{input_path} -s --pdf-engine=xelatex -o #{output_path}")
  end
  
  def send_generated_pdf(output_path)
    # spew the output to the browser
    send_data(File.read(output_path), 
      filename: File.basename("letter.pdf"), 
      :content_type => "application/pdf")
    cookies['download_finished'] = 'true'
  end
end
