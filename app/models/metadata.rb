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
        title = metadata.detect{|e| e[:label] == 'title'}
        if !title.blank?
          if title[:value] != work.title
            work.title = title[:value]
          end
          metadata.delete_if{|e| e[:label] == 'title'}
        end
        identifier = metadata.detect{|e| e[:label] == 'identifier'}
        if !identifier.blank?
          if identifier[:value] != work.identifier
            work.identifier = identifier[:value]
          end
          metadata.delete_if{|e| e[:label] == 'identifier'}
        end
        work.original_metadata=metadata.to_json
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
      raw_metadata_strings = collection.works.pluck(:original_metadata)
      metadata_headers = raw_metadata_strings.map{|raw| raw.nil? ? [] : JSON.parse(raw).map{|element| element["label"] } }.flatten.uniq

      csv << ['work_id', 'title', 'identifier'] + metadata_headers + ['new metadata field 1', 'new metadata field 2'] 

      collection.works.each do |work|
        row = [work.id, work.title, work.identifier]
        unless work.original_metadata.blank?
          metadata = {}
          JSON.parse(work.original_metadata).each {|e| metadata[e['label']] = e['value'] }

          metadata_headers.each do |header|
            # look up the value for this index
            row << metadata[header]
          end
        end

        csv << row
      end
    end

    csv_string
  end
end
