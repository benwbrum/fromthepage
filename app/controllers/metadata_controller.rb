class MetadataController < ApplicationController
  layout false

  def example
    collection = Collection.find(params[:id])
    example = Metadata.create_example(collection)
    send_data example, filename: "example.csv"
  end

  def create
    metadata_file = params[:metadata]['file'].tempfile


    collection = Collection.find(params[:metadata][:collection_id])
    metadata = Metadata.new(metadata_file: metadata_file, collection: collection)
    result = metadata.process_csv
    rows = result[:content]
    row_errors = result[:errors].count
    link = helpers.link_to 'link', collection_metadata_csv_error_path

    if row_errors > 0
      feedback = "Your upload has finished processing. #{rows} works were updated successfully; #{row_errors} rows encountered errors. Download the error file here: #{link}"
    else
      feedback = "Your upload has finished processing. #{rows} works were updated successfully."      
    end

    flash[:alert] = feedback

    ajax_redirect_to edit_look_collection_path(collection.owner, collection)
  end

  def csv_error
    csv_string = Metadata.retrieve_error
    send_data csv_string, filename: "error.csv"
  end
end
