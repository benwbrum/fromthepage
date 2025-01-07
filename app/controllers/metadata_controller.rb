class MetadataController < ApplicationController
  layout false

  def example
    result = Work::Metadata::ExportCsv.call(collection: @collection, works: @collection.works)

    send_data(
      result.csv_string,
      filename: "fromthepage_work_metadata_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv"
    )
  end

  def upload
    # Modal upload
  end

  def create
    metadata_file_path = params[:metadata]['file'].tempfile.path
    collection_id = params[:metadata][:collection_id]
    Work::Metadata::ImportCsvJob.perform_later(metadata_file_path, collection_id, current_user.id)

    collection = Collection.find(collection_id)

    flash[:alert] = t('.is_processing')
    ajax_redirect_to edit_look_collection_path(collection.owner, collection)
  end

  def refresh
    collection = Collection.find(params[:id])

    # Make sure import logs folder exists
    unless Dir.exist?("#{Rails.root}/public/metadata/refresh/log")
      FileUtils.mkdir_p("#{Rails.root}/public/metadata/refresh/log")
    end

    # Create logfile for collection
    log_file = "#{Rails.root}/public/metadata/refresh/log/#{collection.id}_#{Time.current.to_i}_refresh_collection.log"

    rake_call = "#{RAKE} fromthepage:refresh_metadata[#{collection.id},collection] --trace >> #{log_file} 2>&1 &"
    logger.info rake_call
    system(rake_call)

    flash[:notice] = t('.is_processing')
    ajax_redirect_to edit_look_collection_path(collection.owner, collection)
  end
end
