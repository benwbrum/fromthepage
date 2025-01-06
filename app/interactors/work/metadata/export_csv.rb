require 'csv'

class Work::Metadata::ExportCsv
  STATIC_HEADERS = [
    'FromThePage Title',
    '*Collection*',
    '*Document Sets*',
    '*Uploaded Filename*',
    '*FromThePage ID*',
    '*FromThePage Slug*',
    '*FromThePage URL*',
    'FromThePage Description',
    'Identifier',
    '*Originating Manifest ID*',
    '*Creation Date*',
    '*Total Pages*',
    '*Pages Transcribed*',
    '*Pages Corrected*',
    '*Pages Indexed*',
    '*Pages Translated*',
    '*Pages Needing Review*',
    '*Pages Marked Blank*',
    '*Contributors*',
    '*Contributors Name*'
  ].freeze

  STATIC_DESCRIPTION_HEADERS = [
    '*Description Status*',
    '*Described By*'
  ].freeze

  include Interactor
  include Rails.application.routes.url_helpers

  def initialize(collection:, works:)
    @collection = collection
    @works = works

    super
  end

  def call
    csv_string = CSV.generate(force_quotes: true) do |csv|
      works_scope = @works.includes(
                             :document_sets,
                             :work_statistic,
                             :sc_manifest,
                             :deeds,
                             { metadata_description_versions: :user }
                           )
                          .reorder(:id)

      raw_metadata_strings = works_scope.pluck(:original_metadata)
      metadata_headers = raw_metadata_strings
                         .compact
                         .flat_map { |raw| JSON.parse(raw).map { |element| element['label'] } }
                         .uniq

      described_headers = @collection.metadata_fields.map(&:label)
      csv << STATIC_HEADERS + metadata_headers + STATIC_DESCRIPTION_HEADERS + described_headers

      works_scope.each do |work|
        work_users = work.deeds.map { |d| "#{d.user.display_name}<#{d.user.email}>".gsub('|', '//') }.uniq.join('|')
        contributors_real_names = work.deeds.map { |d| d.user.real_name }.uniq.join(' | ')
        row = [
          work.title,
          work.collection.title,
          work.document_sets.map(&:title).join('|'),
          work.uploaded_filename,
          work.id,
          work.slug,
          collection_read_work_url(@collection.owner, @collection, work),
          work.description,
          work.identifier,
          work.sc_manifest.nil? ? '' : work.sc_manifest.at_id,
          work.created_on,
          work.work_statistic.total_pages,
          work.work_statistic.transcribed_pages,
          work.work_statistic.corrected_pages,
          work.work_statistic.annotated_pages,
          work.work_statistic.translated_pages,
          work.work_statistic.needs_review,
          work.work_statistic.blank_pages,
          work_users,
          contributors_real_names
        ]

        if work.original_metadata.present?
          metadata = {}
          JSON.parse(work.original_metadata).each { |e| metadata[e['label']] = e['value'] }

          metadata_headers.each do |header|
            # look up the value for this index
            row << metadata[header]
          end
        end

        if work.metadata_description.present?
          # description status
          row << work.description_status
          # described by
          row << work.metadata_description_versions.flat_map(&:user).map(&:display_name).join('; ')

          metadata = JSON.parse(work.metadata_description)

          # we rely on a consistent order of fields returned by collection.metadata_fields to prevent scrambling columns
          @collection.metadata_fields.each do |field|
            element = metadata.detect { |candidate| candidate['transcription_field_id'] == field.id }
            if element
              value = element['value']
              value = value.join('; ') if value.is_a? Array
              row << value
            else
              row << nil
            end
          end
        end

        csv << row
      end
    end

    context.csv_string = csv_string
    context
  end
end
