class MetadataCsv
  def initialize(metadata_file:, collection:)
    @rowset = []
    @rowset_errors = []
    @new_metadata = []
    @metadata_file = metadata_file
    @collection = collection
  end

  def process_csv
    rows = CSV.open(@metadata_file)
    rows.shift

    # push all rows to a rowset first.
    rows.each do |row|
      @rowset << { work_id: row[0], title: row[1] }
    end

    # process the rowset.
    @rowset.each do |rs|
      rs.each do |r|
        @new_metadata << { label: r[0],  value: r[1] }
      end

      begin
        work = Work.find(rs[:work_id].to_i)
        work.original_metadata = @new_metadata.to_json
        work.save

        unless @collection.works.include?(work)
          @rowset_errors << { error: "No work with ID #{rs[:work_id]} is in collection #{@collection.title}",
                              work_id: rs[:work_id],
                              title: rs[:title] }
        end
      rescue ActiveRecord::RecordNotFound
        @rowset_errors << { error: "No work exists with ID #{rs[:work_id]}",
                            work_id: rs[:work_id],
                            title: rs[:title] }

        # write the error.csv to the filesystem.
        output_file(@rowset_errors)
      end
    end

    result = { content: @rowset, errors: @rowset_errors }
    result
  end

  def output_file(rowset_errors)
    CSV.open('/tmp/error.csv', 'wb') do |csv|

      rowset_errors.each do |re|
        csv << [re[:error], re[:work_id], re[:title]]
      end
    end
  end

  def self.process_error
    rows = CSV.parse(File.open('/tmp/error.csv'))

    # delete the file after we are done reading it.
    File.delete('/tmp/error.csv')

    csv_string = CSV.generate(headers: true) do |csv|
      csv << ['error', 'work_id', 'title']

      rows.each do |r|
        csv << r
      end
    end

    csv_string
  end

  def self.example(collection)
    csv_string = CSV.generate(headers: true) do |csv|
      csv << ['work_id', 'title', 'your metadata_field_one', 'your_metadata_field_two']

      collection.works.each do |work|
        csv << [work.id, work.title]
      end
    end

    csv_string
  end
end
