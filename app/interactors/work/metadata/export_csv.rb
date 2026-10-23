require 'csv'

class Work::Metadata::ExportCsv < ApplicationInteractor
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

  include Rails.application.routes.url_helpers

  attr_accessor :csv_string

  def initialize(collection:, works:)
    @collection = collection
    @works = works

    super
  end

  def perform
    @csv_string = CSV.generate(force_quotes: true) do |csv|
      works_scope = @works.includes(
                             :document_sets,
                             :work_statistic,
                             :sc_manifest,
                             :deeds,
                             :ai_work_metadata,
                             { metadata_description_versions: :user }
                           )
                          .reorder(:id)

      raw_metadata_strings = works_scope.pluck(:original_metadata)
      metadata_headers = raw_metadata_strings
                         .compact
                         .flat_map { |raw| JSON.parse(raw).map { |element| element['label'] } }
                         .uniq

      metadata_fields = @collection.metadata_fields.to_a
      described_headers = metadata_fields.map(&:label)
      include_ai_drafts = @collection.ai_work_metadata_enabled?
      ai_draft_headers = include_ai_drafts ? described_headers.map { |header| "#{header} (AI Draft)" } : []
      ai_draft_headers.unshift('*AI Draft Provenance*') if include_ai_drafts
      csv << STATIC_HEADERS + metadata_headers + STATIC_DESCRIPTION_HEADERS + described_headers + ai_draft_headers

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
          work.sc_manifest&.at_id.presence || '',
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
        else
          row.concat(Array.new(metadata_headers.size))
        end

        if work.metadata_description.present?
          # description status
          row << work.description_status
          # described by
          row << work.metadata_description_versions.flat_map(&:user).map(&:display_name).join('; ')

          metadata = JSON.parse(work.metadata_description)

          # we rely on a consistent order of fields returned by collection.metadata_fields to prevent scrambling columns
          metadata_fields.each do |field|
            element = metadata.detect { |candidate| candidate['transcription_field_id'] == field.id }
            if element
              value = element['value']
              value = value.join('; ') if value.is_a? Array
              row << value
            else
              row << nil
            end
          end
        else
          row.concat(Array.new(STATIC_DESCRIPTION_HEADERS.size + metadata_fields.size))
        end

        if include_ai_drafts
          draft = work.ai_work_metadata.select(&:status_finished?).max_by { |record| [record.created_at, record.id] }
          draft_metadata = draft&.metadata_json || {}
          row << (draft ? "#{draft.model} at #{draft.created_at.utc.iso8601}" : nil)

          metadata_fields.each do |field|
            value = draft_metadata[field.id.to_s]
            row << (value.is_a?(Array) ? value.join('; ') : value)
          end
        end

        csv << row
      end
    end
  end
end
