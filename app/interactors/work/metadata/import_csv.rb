require 'csv'

class Work::Metadata::ImportCsv < ApplicationInteractor
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
    'Identifier',
    '*Uploaded Filename*'
  ].freeze

  ADDITIONAL_METADATA_HEADERS = {
    author: 'Author',
    recipient: 'Recipient',
    location_of_composition: 'Place of Creation',
    genre: 'Genre',
    source_location: 'Source Location',
    source_collection_name: 'Source Collection Name',
    source_box_folder: 'Source Box/Folder',
    in_scope: 'In Scope',
    editorial_notes: 'Editorial notes',
    physical_description: 'Physical description',
    document_history: 'Document history',
    permission_description: 'Permission description'
  }.freeze

  attr_accessor :content, :rowset_errors

  def initialize(metadata_file:, collection:)
    @metadata_file = metadata_file
    @collection = collection
    @content = 0
    @rowset_errors = []

    super
  end

  def perform
    csv = read_csv(@metadata_file)

    csv.each do |row|
      metadata = []
      csv.headers.each do |header|
        # Skip protected headers
        next if header.include?('*')

        # Skip special headers
        next if SPECIAL_HEADERS.include?(header)

        # Skip additional_metadata_headers
        next if ADDITIONAL_METADATA_HEADERS.values.include?(header)

        metadata << { label: header, value: row[header] } if row[header].present?
      end

      # Assign special headers value
      work_id = row['*FromThePage ID*'] || row['work_id']
      work_title = row['FromThePage Title'] || row['title']
      work_description = row['FromThePage Description'] || row['description']
      work_filename = row['*Uploaded Filename*'] || row['filename']
      work_identifier = row['Identifier'] || row['identifier']

      if work_id.present?
        work = Work.find_by(id: work_id.to_i)
      elsif work_filename.present?
        clean_filename = work_filename.sub(File.extname(work_filename), '')
        work = Work.find_by(uploaded_filename: clean_filename)
      else
        work = nil
      end

      if work.nil?
        @rowset_errors << nil_work_row_error(work_id, work_title, work_filename)
      elsif work.collection != @collection
        @rowset_errors << {
          error: I18n.t('metadata.import_csv.errors.not_in_collection', work_id: work_id, collection_title: @collection.title),
          work_id: work_id,
          title: work_title
        }
      else
        work.title = work_title if work_title.present?
        work.identifier = work_identifier if work_identifier.present?
        work.description = work_description if work_description.present?
        work.original_metadata = metadata.to_json if metadata.present?
        work.assign_attributes(additional_metadata_attributes(row))

        work.save!

        @content += 1
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
    if work_id.present?
      {
        error: I18n.t('metadata.import_csv.errors.not_existing_work_id', work_id: work_id),
        work_id: work_id,
        title: work_title
      }
    elsif work_filename.blank?
      { error: I18n.t('metadata.import_csv.errors.filename_blank') }
    else
      { error: I18n.t('metadata.import_csv.errors.not_existing_work', work_filename: work_filename) }
    end
  end

  def additional_metadata_attributes(row)
    attributes_hash = {}
    ADDITIONAL_METADATA_HEADERS.each do |key, header|
      value = row[header]

      next if value.nil? || value == ''
      # When value is '', we leave unchanged
      # Otherwise, we expect ' ' for setting the field to nil

      attributes_hash[key] = value == ' ' ? nil : value
    end

    attributes_hash
  end
end
