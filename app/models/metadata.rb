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
      csv = CSV.read(@metadata_file, :headers=>true)
    rescue
      contents = File.read(@metadata_file)
      detection = CharlockHolmes::EncodingDetector.detect(contents)

      csv = CSV.read(@metadata_file, 
                      :encoding => "bom|#{detection[:encoding]}",
                      :liberal_parsing => true,
                      :headers => true)
    end
    success = 0
    csv.each do |row|
      metadata = []
      csv.headers.each do |header|
        if row[header] && header != 'work_id' #&& header != 'filename'
          metadata << { label: header,  value: row[header] }
        end
      end

      work_id = row['work_id']
      if work_id
        work = Work.where(id: work_id.to_i).first
      else
        raw_filename = row['filename']
        if raw_filename.blank?
          work=nil
        else
          clean_filename = raw_filename.sub(File.extname(raw_filename),'')
          work = Work.where(uploaded_filename: clean_filename).first
        end
      end

      if work.nil?
        if work_id
          @rowset_errors << { error: "No work exists with ID #{row['work_id']}",
          work_id: row['work_id'],
          title: row['title'] }        
        elsif row['filename'].blank?
          @rowset_errors << { error: "No work filename or work ID valeus were in the uploaded file" }          
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
        work.original_metadata=metadata.to_json
        title = metadata.detect{|e| e[:label] == 'title'}
        if !title.blank? && title[:value] != work.title
          work.title = title[:value]
        end
        work.save!
        success+=1
      end
    end

    # we should update metadata coverage after this

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
