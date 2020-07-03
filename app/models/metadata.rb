class Metadata
  def initialize(metadata_file:, collection:)
    @rowset_errors = []
    @new_metadata = []
    @canonical_metadata = []
    @metadata_file = metadata_file
    @collection = collection
  end

  def process_csv
    begin
      csv = CSV.open(@metadata_file)
      headers = csv.shift
    rescue CSV::MalformedCSVError
      csv = CSV.open(@metadata_file, :encoding => "ISO8859-1")
      headers = csv.shift
    end

    rows = CSV.parse(@metadata_file).map { |a| Hash[ headers.zip(a) ] }
    rows.shift

    # process rows.
    rows.each do |row|
      if row.include?('work_id')
        row.each do |r|
          @new_metadata << { label: r[0],  value: r[1] }
        end

        begin
          work = Work.find(row['work_id'].to_i)
          work.update(original_metadata: @new_metadata.to_json)

          unless @collection.works.include?(work)
            @rowset_errors << { error: "No work with ID #{row['work_id']} is in collection #{@collection.title}",
                                work_id: row['work_id'],
                                title: row['title'] }
          end
        rescue ActiveRecord::RecordNotFound
          @rowset_errors << { error: "No work exists with ID #{row['work_id']}",
                              work_id: row['work_id'],
                              title: row['title'] }

          # write the error.csv to the filesystem.
          output_file(@rowset_errors)
        end
      elsif row.include?('filename')
        work = Work.where(uploaded_filename: row['filename']).first

        if work.nil?
          @rowset_errors << { error: "No work exists with filename #{row['filename']}" }
          output_file(@rowset_errors)
        else
          row.each do |k, v|
            encval = v.force_encoding('ISO-8859-1') unless v.nil?
            @new_metadata << { label: k, value: encval }
          end

          work.update(original_metadata: @new_metadata.to_json)
        end
      end
    end

    result = { content: rows, errors: @rowset_errors }
    result
  end

  def save_canonical_metadata(work)
    collection = work.collection

    om = JSON.parse(work.original_metadata)

    om.each do |m|
      unless m['label'].blank?
        # check if record exist
        # increment count field +1 if a record is returned, otherwise create it.
        test = collection.metadata_coverages.where(key: m['label'].downcase.split.join('_').to_s).first

        if test
          test.count = test.count + 1
          test.save
        end

        if test.nil?
          mc = collection.metadata_coverages.build
          mc.key = m['label'].downcase.split.join('_').to_sym
          mc.save
          mc.create_facet_config(metadata_coverage_id: mc.collection_id)
        end
      end
    end
  end

  def output_file(rowset_errors)
    CSV.open('/tmp/error.csv', 'wb') do |csv|

      rowset_errors.each do |r|
        csv << [r[:error], r[:work_id], r[:title]]
      end
    end
  end

  def self.retrieve_error
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

  def self.create_example(collection)
    csv_string = CSV.generate(headers: true) do |csv|
      csv << ['work_id', 'title', 'your metadata_field_one', 'your_metadata_field_two']

      collection.works.each do |work|
        csv << [work.id, work.title]
      end
    end

    csv_string
  end
end
