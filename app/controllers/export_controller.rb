require 'contentdm_translator'

class ExportController < ApplicationController
  require 'zip'

  include CollectionHelper
  include ExportHelper
  include ExportService

  DEFAULT_WORKS_PER_PAGE = 15

  before_action :require_owner, only: [:index]

  def index
    filtered_data

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    xhtml = work_to_xhtml(@work)

    render text: xhtml, layout: false
  end

  def printable
    result = Work::Export::Printable.new(
      work: @work,
      format: params[:format],
      edition: params[:edition],
      include_metadata: true,
      include_contributors: true,
      include_notes: false,
      preserve_lb: false
    ).call

    if result.success?
      send_data(
        File.read(result.file),
        filename: result.filename,
        content_type: result.content_type
      )

      cookies['download_finished'] = 'true'
    else
      head :internal_server_error
    end
  end

  def tei
    tei_xml = work_to_tei(@work, current_user)

    render text: tei_xml, content_type: 'application/xml', layout: false
  end

  def subject_details_csv
    send_data(
      @collection.export_subject_details_as_csv,
      filename: "fromthepage_subject_details_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
      type: 'application/csv'
    )
    cookies['download_finished'] = 'true'
  end

  def subject_coocurrence_csv
    send_data(
      @collection.export_subject_coocurrence_as_csv,
      filename: "fromthepage_subject_coocurrence_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
      type: 'application/csv'
    )
    cookies['download_finished'] = 'true'
  end

  def subject_distribution_csv
    send_data(
      @collection.export_subject_distribution_as_csv(@article),
      filename: "fromthepage_subject_distribution_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
      type: 'application/csv'
    )
    cookies['download_finished'] = 'true'
  end

  def subject_index_csv
    send_data(
      @collection.export_subject_index_as_csv(@collection.works),
      filename: "fromthepage_subject_index_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
      type: 'application/csv'
    )
    cookies['download_finished'] = 'true'
  end

  def work_metadata_csv
    filename = params[:filename] ? "#{params[:filename]}.csv" : "fromthepage_work_metadata_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv"
    result = Work::Metadata::ExportCsv.new(collection: @collection, works: @collection.works).call

    send_data(
      result.csv_string,
      filename: filename,
      type: 'application/csv'
    )
    cookies['download_finished'] = 'true'
  end

  def table_csv
    filename = "fromthepage_tables_export_#{@work.id}_#{Time.now.utc.iso8601}.csv"
    collection = @work.collection

    if collection.field_based?
      result = Work::Table::ExportCsv.new(
        collection: collection,
        work_ids: [@work.id]
      ).call

      raise 'Failed to export csv' unless result.success?

      csv_string = result.csv_string
    else
      csv_string = export_tables_as_csv(@work)
    end

    send_data(
      csv_string,
      filename: filename,
      type: 'text/csv'
    )
    cookies['download_finished'] = 'true'
  end

  def export_all_tables
    filename = "fromthepage_tables_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv"

    if @collection.field_based?
      result = Work::Table::ExportCsv.new(
        collection: @collection,
        work_ids: @collection.works.pluck(:id)
      ).call

      csv_string = result.csv_string
    else
      csv_string = export_tables_as_csv(@collection)
    end
    send_data(
      csv_string,
      filename: filename,
      type: 'application/csv'
    )
    cookies['download_finished'] = 'true'
  end

  def page_plaintext_verbatim
    render  layout: false, content_type: 'text/plain', plain: @page.verbatim_transcription_plaintext
  end

  def page_plaintext_translation_verbatim
    render  layout: false, content_type: 'text/plain', plain: @page.verbatim_translation_plaintext
  end

  def page_plaintext_emended
    render  layout: false, content_type: 'text/plain', plain: @page.emended_transcription_plaintext
  end

  def page_plaintext_translation_emended
    render  layout: false, content_type: 'text/plain', plain: @page.emended_translation_plaintext
  end

  def page_plaintext_searchable
    render  layout: false, content_type: 'text/plain', plain: @page.search_text
  end

  def work_plaintext_verbatim
    render  layout: false, content_type: 'text/plain', plain: @work.verbatim_transcription_plaintext
  end

  def work_plaintext_translation_verbatim
    render  layout: false, content_type: 'text/plain', plain: @work.verbatim_translation_plaintext
  end

  def work_plaintext_emended
    render  layout: false, content_type: 'text/plain', plain: @work.emended_transcription_plaintext
  end

  def work_plaintext_translation_emended
    render  layout: false, content_type: 'text/plain', plain: @work.emended_translation_plaintext
  end

  def work_plaintext_searchable
    render  layout: false, content_type: 'text/plain', plain: @work.searchable_plaintext
  end

  def edit_contentdm_credentials
    @sync_target = @collection
    @cdm_collection = cdm_collection_for(@sync_target)

    if ContentdmTranslator.collection_is_cdm?(@sync_target)
      begin
        field_config = ContentdmTranslator.fetch_cdm_field_config(@sync_target)
        @cdm_fulltext_fields = field_config.select { |e| e['type'] == 'FTS' }.map { |e| [e['name'], e['nick']] }
        @cdm_metadata_fields = field_config.map { |e| [e['name'], e['nick']] }
      rescue => e
        Rails.logger.error("Failed to fetch CONTENTdm field config: #{e.message}")
      end
    end
  end

  # TODO: Add specs for this
  def update_contentdm_credentials
    # test credentials
    license_key = params[:collection][:license_key]
    contentdm_user_name = params[:contentdm_user_name]
    contentdm_password = params[:contentdm_password]
    error_message, _fts_field = ContentdmTranslator.fts_field_for_collection(@collection)

    # persist license key and export settings so the user doesn't have to retype them
    if error_message.blank? || !error_message.match(/license.*invalid/)
      cdm_collection = cdm_collection_for(@collection)
      cdm_collection.license_key = license_key
      cdm_collection.save!

      cdm_setting = cdm_collection.cdm_export_setting || cdm_collection.build_cdm_export_setting
      cdm_setting.transcript_source    = params[:transcript_source].presence || CdmExportSetting::HUMAN_ONLY
      cdm_setting.fulltext_field       = params[:cdm_fulltext_field].presence
      cdm_setting.include_ai_provenance = params[:include_ai_provenance] == '1'
      cdm_setting.ai_provenance_field  = params[:cdm_ai_provenance_field].presence
      cdm_setting.prepend_ai_warning   = params[:prepend_ai_warning] == '1'
      cdm_setting.save!
    end

    # redirect to or render edit screen with error
    if error_message
      flash[:error] = error_message
      @sync_target = @collection
      @cdm_collection = cdm_collection_for(@sync_target)
      render action: :edit_contentdm_credentials, collection_id: @collection.slug
      return
    end

    # pass credentials, FTS field, and search to background job
    log_file = ContentdmTranslator.log_file(@collection)
    FileUtils.mkdir_p(File.dirname(log_file)) unless Dir.exist? File.dirname(log_file)
    cmd = "rake fromthepage:cdm_transcript_export[#{@collection.slug}] > #{log_file} 2>&1 &"
    logger.info(cmd)
    system({ 'contentdm_username' => contentdm_user_name, 'contentdm_password' => contentdm_password, 'contentdm_license' => license_key }, cmd)

    # display results somehow
    flash[:notice] = t('.updating_contentdm_message')
    ajax_redirect_to action: :index, collection_id: @collection.slug
  end

  private

  def cdm_collection_for(collection_or_set)
    collection_or_set.is_a?(DocumentSet) ? collection_or_set.collection : collection_or_set
  end

  def require_owner
    unless user_signed_in? && current_user.like_owner?(@collection)
      redirect_to main_app.dashboard_path
    end
  end

  def filtered_data
    @sorting = (params[:sort] || 'title').to_sym
    @ordering = (params[:order] || 'ASC').downcase.to_sym
    @ordering = [:asc, :desc].include?(@ordering) ? @ordering : :desc

    # Check if there are any translated works in the collection
    @header = @collection.works.where(supports_translation: true).exists? ? 'Translated' : 'Transcribed'

    @works = params[:search].blank? ? @collection.works : @collection.search_works(params[:search])
    @works = @works.includes(:work_statistic)

    @work_stats_hash_map = {}
    @works.each do |work|
      work_stats(work)
      @work_stats_hash_map[work.id] = {
        progress_annotated: @progress_annotated,
        progress_review: @progress_review,
        progress_completed: @progress_completed
      }
    end

    sort_filtered_data

    if params[:per_page] != '-1'
      @works = @works.paginate(page: params[:page], per_page: params[:per_page] || DEFAULT_WORKS_PER_PAGE)
    end

    @table_export = @collection.works.joins(:table_cells).where.not(table_cells: { work_id: nil }).distinct
  end

  def sort_filtered_data
    case @sorting
    when :page_count
      sorting_arguments = "work_statistics.total_pages #{@ordering}"
    when :indexed_count
      ordered_work_ids = calculate_ordered_work_ids(:progress_annotated)
      ordered_work_ids.reverse! if @ordering == :desc

      sorting_arguments = "FIELD(id, #{ordered_work_ids.join(',')})"
    when :completed_count
      ordered_work_ids = calculate_ordered_work_ids(:progress_completed)
      ordered_work_ids.reverse! if @ordering == :desc

      sorting_arguments = "FIELD(id, #{ordered_work_ids.join(',')})"
    when :reviewed_count
      ordered_work_ids = calculate_ordered_work_ids(:progress_review)
      ordered_work_ids.reverse! if @ordering == :desc

      sorting_arguments = "FIELD(id, #{ordered_work_ids.join(',')})"
    else
      sorting_arguments = "title #{@ordering}"
    end

    @works = @works.reorder(Arel.sql(sorting_arguments))
  end

  def calculate_ordered_work_ids(key)
    @works.sort_by do |work|
      @work_stats_hash_map[work.id][key]
    end.pluck(:id)
  end
end
