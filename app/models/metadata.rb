class Metadata
  def initialize(metadata_file:, collection:)
    @rowset_errors = []
    @new_metadata = []
    @canonical_metadata = []
    @metadata_file = metadata_file
    @collection = collection
  end


  def process_csv
    csv = CSV.read(@metadata_file, :headers=>true)
    success = 0
    csv.each do |row|
      metadata = []
      csv.headers.each do |header|
        if row[header] && header != 'work_id' && header != 'filename'
          metadata << { label: header,  value: row[header] }
        end
      end

      work_id = row['work_id']
      if work_id
        work = Work.where(id: work_id.to_i).first
      else
        work = Work.where(uploaded_filename: row['filename']).first
      end

      if work.nil?
        if work_id
          @rowset_errors << { error: "No work exists with ID #{row['work_id']}",
          work_id: row['work_id'],
          title: row['title'] }        
        else
          @rowset_errors << { error: "No work exists with filename #{row['filename']}" }
        end
        output_file(@rowset_errors)
      elsif work.collection != @collection
        @rowset_errors << { error: "No work with ID #{row['work_id']} is in collection #{@collection.title}",
        work_id: row['work_id'],
        title: row['title'] }
        output_file(@rowset_errors)
      else
        work.update_column(:original_metadata, metadata.to_json)
        success+=1
      end
    end

    result = { content: success, errors: @rowset_errors }
    result
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
