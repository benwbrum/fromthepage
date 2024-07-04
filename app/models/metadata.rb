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
      csv = CSV.read(@metadata_file, headers: true)
    rescue StandardError
      contents = File.read(@metadata_file)
      detection = CharlockHolmes::EncodingDetector.detect(contents)

      csv = CSV.read(@metadata_file,
        encoding: "bom|#{detection[:encoding]}",
        liberal_parsing: true,
        headers: true)
    end
    success = 0
    csv.each do |row|
      metadata = []
      csv.headers.each do |header|
        metadata << { label: header, value: row[header] } if row[header] && header != 'work_id' # && header != 'filename'
      end

      work_id = row['work_id']
      if work_id
        work = Work.where(id: work_id.to_i).first
      else
        raw_filename = row['filename']
        if raw_filename.blank?
          work = nil
        else
          clean_filename = raw_filename.sub(File.extname(raw_filename), '')
          work = Work.where(uploaded_filename: clean_filename).first
        end
      end

      if work.nil?
        if work_id
          @rowset_errors << {
            error: "No work exists with ID #{row['work_id']}",
            work_id: row['work_id'],
            title: row['title']
          }
        elsif row['filename'].blank?
          @rowset_errors << { error: 'No work filename or work ID valeus were in the uploaded file' }
        else
          @rowset_errors << { error: "No work exists with filename #{row['filename']}" }
        end
        output_file(@rowset_errors)
      elsif work.collection != @collection
        @rowset_errors << {
          error: "No work with ID #{row['work_id']} is in collection #{@collection.title}",
          work_id: row['work_id'],
          title: row['title']
        }
        output_file(@rowset_errors)
      else
        title = metadata.detect { |e| e[:label] == 'title' }
        if title.present?
          work.title = title[:value] if title[:value] != work.title
          metadata.delete_if { |e| e[:label] == 'title' }
        end
        identifier = metadata.detect { |e| e[:label] == 'identifier' }
        if identifier.present?
          work.identifier = identifier[:value] if identifier[:value] != work.identifier
          metadata.delete_if { |e| e[:label] == 'identifier' }
        end
        description = metadata.detect { |e| e[:label] == 'description' }
        if description.present?
          work.description = description[:value] if description[:value] != work.description
          metadata.delete_if { |e| e[:label] == 'description' }
        end
        work.original_metadata = metadata.to_json
        work.save!
        success += 1
      end
    end

    # we should update metadata coverage after this

    { content: success, errors: @rowset_errors }
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

    CSV.generate(headers: true) do |csv|
      csv << ['error', 'work_id', 'title']

      rows.each do |r|
        csv << r
      end
    end
  end

  def self.create_example(collection)
    CSV.generate(headers: true) do |csv|
      raw_metadata_strings = collection.works.pluck(:original_metadata)
      metadata_headers = raw_metadata_strings.map { |raw| raw.nil? ? [] : JSON.parse(raw).pluck('label') }.flatten.uniq

      csv << (['work_id', 'title', 'identifier', 'description'] + metadata_headers + ['new metadata field 1', 'new metadata field 2'])

      collection.works.each do |work|
        row = [work.id, work.title, work.identifier, work.description]
        if work.original_metadata.present?
          metadata = {}
          JSON.parse(work.original_metadata).each { |e| metadata[e['label']] = e['value'] }

          metadata_headers.each do |header|
            # look up the value for this index
            row << metadata[header]
          end
        end

        csv << row
      end
    end
  end

end
