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
end
