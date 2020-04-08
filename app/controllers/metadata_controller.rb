class MetadataController < ApplicationController
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:upload]

  ROWSET = []
  ROWSET_ERRORS = []

  def example
    @collection = Collection.find(params[:id])

    csv_string = CSV.generate(headers: true) do |csv|
      csv << ['work_id', 'title', 'your metadata_field_one', 'your_metadata_field_two']

      @collection.works.each do |work|
        csv << [work.id, work.title]
      end
    end

    send_data csv_string, filename: "example.csv"
  end

  def upload
  end

  def create
    metadata_file = params[:metadata]['file'].tempfile
    rows = CSV.open(metadata_file)
    rows.shift

    collection = Collection.find(params[:metadata][:collection_id])

    # push all rows to a rowset first.
    rows.each do |row|
      ROWSET << { work_id: row[0], title: row[1] }
    end

    # process the rowset.
    ROWSET.each do |rs|
      new_metadata = []

      rs.each do |r|
        new_metadata << { label: r[0],  value: r[1] }
      end

      begin
        work = Work.find(rs[:work_id].to_i)
        work.original_metadata = new_metadata.to_json
        work.save

        unless collection.works.include?(work)
          ROWSET_ERRORS << { error: "No work with ID #{rs[:work_id]} is in collection #{collection.title}",
                             work_id: rs[:work_id],
                             title: rs[:title] }
        end
      rescue ActiveRecord::RecordNotFound
        ROWSET_ERRORS << { error: "No work exists with ID #{rs[:work_id]}",
                           work_id: rs[:work_id],
                           title: rs[:title] }
      end
    end

    flash[:alert] = "Your upload has finished processing. #{ROWSET.count} rows were updated successfully, #{ROWSET_ERRORS.count} rows encountered errors. Download the error file here: #{helpers.link_to 'link', collection_metadata_csv_error_path}"
    ajax_redirect_to edit_collection_path(collection.owner, collection)
  end

  def csv_error
    # write the error.csv
    csv_string = CSV.generate(headers: true) do |csv|
      csv << ['error', 'work_id', 'title']

      ROWSET_ERRORS.each do |re|
        csv << [re[:error], re[:work_id], re[:title]]
      end
    end

    send_data csv_string, filename: "error.csv"
  end
end
