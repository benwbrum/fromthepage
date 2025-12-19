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
    uploaded_io   = params[:metadata]['file']
    collection_id = params[:metadata][:collection_id]

    import_dir = Rails.root.join('tmp', 'import_csv')
    FileUtils.mkdir_p(import_dir)

    ext       = File.extname(uploaded_io.original_filename)
    filename  = "#{Time.current.to_i}#{ext}"
    metadata_file_path = import_dir.join(filename)

    File.open(metadata_file_path, 'wb') do |f|
      f.write(uploaded_io.read)
    end

    Work::Metadata::ImportCsvJob.perform_later(
      metadata_file_path: metadata_file_path.to_s,
      collection_id: collection_id,
      user_id: current_user.id
    )

    collection = Collection.find(collection_id)

    flash[:alert] = t('.is_processing')
    ajax_redirect_to edit_look_collection_path(collection.owner, collection)
  end

  def refresh
    collection = Collection.find(params[:id])

    Metadata::RefreshJob.perform_later(id: collection.id, type: 'collection', user_id: current_user.id)

    # TODO: Use turbo_stream redirect when #4174 is merged
    flash[:notice] = t('.is_processing')
    ajax_redirect_to edit_look_collection_path(collection.owner, collection)
  end
end
