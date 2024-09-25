class Metadata
  SPECIAL_HEADERS = [
    # legacy headers
    'work_id',
    'title',
    'description',
    'identifier',
    # updated headers
    '*FromThePage ID*',
    'FromThePage Title',
    'FromThePage Description',
    'FromThePage Identifier',
    '*Uploaded Filename*'
  ].freeze

  def initialize(metadata_file:, collection:)
    @rowset_errors = []
    @new_metadata = []
    @canonical_metadata = []
    @metadata_file = metadata_file
    @collection = collection
  end

  def process_csv
    csv = read_csv(@metadata_file)
    success = 0
    csv.each do |row|
      metadata = []
      csv.headers.each do |header|
        # Skip protected headers
        next if header&.include?('*')

        # Skip special headers
        next if SPECIAL_HEADERS.include?(header)

        metadata << { label: header, value: row[header] } if row[header]
      end

      # Assign special headers value
      work_id = row['*FromThePage ID*'] || row['work_id']
      work_title = row['FromThePage Title'] || row['title']
      work_description = row['FromThePage Description'] || row['description']
      work_identifier = row['FromThePage Identifier'] || row['identifier']
      work_filename = row['*Uploaded Filename*'] || row['filename']

      if work_id.present?
        work = Work.where(id: work_id.to_i).first
      elsif work_filename.present?
        clean_filename = work_filename.sub(File.extname(work_filename), '')
        work = Work.where(uploaded_filename: clean_filename).first
      else
        work = nil
      end

      if work.nil?
        @rowset_errors << nil_work_row_error(work_id, work_title, work_filename)
        output_file(@rowset_errors)
      elsif work.collection != @collection
        @rowset_errors << {
          error: "No work with ID #{work_id} is in collection #{@collection.title}",
          work_id: work_id,
          title: work_title
        }
        output_file(@rowset_errors)
      else
        work.title = work_title if work_title.present?
        work.identifier = work_identifier if work_identifier.present?
        work.description = work_description if work_description.present?
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
      metadata_headers = raw_metadata_strings
                         .compact
                         .flat_map { |raw| JSON.parse(raw).map { |element| element['label'] } }
                         .uniq

      csv << ['*FromThePage ID*', 'FromThePage Title', 'FromThePage Identifier', 'FromThePage Description'] +
             metadata_headers +
             ['new metadata field 1', 'new metadata field 2']

      collection.works.each do |work|
        row = [work.id, work.title, work.identifier, work.description]
        unless work.original_metadata.blank?
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

  private

  def read_csv(metadata_file)
    CSV.read(metadata_file, headers: true)
  rescue StandardError
    contents = File.read(metadata_file)
    detection = CharlockHolmes::EncodingDetector.detect(contents)

    CSV.read(
      metadata_file,
      encoding: "bom|#{detection[:encoding]}",
      liberal_parsing: true,
      headers: true
    )
  end

  def nil_work_row_error(work_id, work_title, work_filename)
    if work_id
      { error: "No work exists with ID #{work_id}", work_id: work_id, title: work_title }
    elsif work_filename.blank?
      { error: 'No work filename or work ID valeus were in the uploaded file' }
    else
      { error: "No work exists with filename #{work_filename}" }
    end
  end
end
