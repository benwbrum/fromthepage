class MetadataController < ApplicationController
  layout false

  def example
    result = Work::Metadata::ExportCsv.new(collection: @collection, works: @collection.works).call

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

    Metadata::RefreshJob.perform_later(id: collection.id, type: 'collection', user: current_user)

    # TODO: Use turbo_stream redirect when #4174 is merged
    flash[:notice] = t('.is_processing')
    ajax_redirect_to edit_look_collection_path(collection.owner, collection)
  end
end
