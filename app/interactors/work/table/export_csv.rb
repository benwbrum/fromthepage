require 'csv'

class Work::Table::ExportCsv < ApplicationInteractor
  STATIC_HEADERS = [
    'Work Title',
    'Work Identifier',
    'FromThePage Identifier',
    'Page Title',
    'Page Position',
    'Page URL',
    'Page Contributors',
    'Page Notes',
    'Page Status'
  ].freeze

  include Rails.application.routes.url_helpers

  attr_accessor :csv_string

  def initialize(collection:, works:)
    @collection = collection
    @works = works
    @owner = @collection.owner

    super
  end

  def perform
    @csv_string = CSV.generate(force_quotes: true) do |csv|
      csv << STATIC_HEADERS + page_metadata_headers + field_headers

      @works.each do |work|
        work_deeds = work.deeds
        work.pages.each do |page|
          parse_page(work, page, work_deeds, 0).each do |row|
            csv << row
          end
        end
      end
    end
  end

  private

  def parse_page(work, page, work_deeds, row_index)
    rows = []
    max_row_size = 0

    base_row = [
      work.title,
      work.identifier,
      work.id,
      page.title,
      page.position,
      collection_display_page_url(@owner, @collection, work, page),
      work_deeds.where(page_id: page.id)
                .map{ |d| "#{d.user.display_name}<#{d.user.email}>".gsub('|', '//') }
                .uniq.join('|'),
      page.notes
          .map{ |n| "[#{n.user.display_name}<#{n.user.email}>]: #{n.body}" }.join('|').gsub('|', '//').gsub(/\s+/, ' '),
      I18n.t("page.edit.page_status_#{page.status}")
    ]
    base_row += page_metadata_headers.map { |header| page.metadata[header] }

    loop do
      row = base_row.dup

      field_objects.each do |field|
        if field.is_a?(SpreadsheetColumn)
          parent_field = field.transcription_field

          row_columns = page.transcription_json[parent_field.id.to_s] || []
          max_row_size = [max_row_size, row_columns.size].max

          row << row_columns[row_index]&.dig(field.id.to_s) || ''
        else
          row << page.transcription_json[field.id.to_s] || ''
        end
      end

      rows << row
      row_index += 1

      break unless row_index < max_row_size
    end

    rows
  end

  def transcription_fields
    @transcription_fields ||= @collection.transcription_fields
                                         .where.not(input_type: 'instruction')
                                         .order(:line_number, :position)
  end

  def spreadsheet_columns_map
    @spreadsheet_columns_map ||= SpreadsheetColumn.where(transcription_field_id: transcription_fields.select(:id))
                                                  .order(:position)
                                                  .group_by(&:transcription_field_id)
  end

  def page_metadata_headers
    @page_metadata_headers ||= @collection.page_metadata_fields
  end

  def field_objects
    return @field_objects if defined?(@field_objects)

    @field_objects = []

    transcription_fields.each do |transcription_field|
      if transcription_field.input_type == 'spreadsheet'
        spreadsheet_columns_map[transcription_field.id]&.each do |spreadsheet_column|
          @field_objects << spreadsheet_column
        end
      else
        @field_objects << transcription_field
      end
    end

    @field_objects
  end

  def field_headers
    return @field_headers if defined?(@field_headers)

    @field_headers = field_objects.map do |field_object|
      if field_object.is_a?(SpreadsheetColumn)
        "#{field_object.transcription_field.label} #{field_object.label}"
      else
        field_object.label
      end
    end

    @field_headers
  end
end
