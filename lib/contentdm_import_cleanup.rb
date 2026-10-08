require 'contentdm_translator'

# Repair only the narrow, recognizable signature of a blank CONTENTdm import
# followed immediately by an identical snapshot. Human/OCR content is retained.
class ContentdmImportCleanup
  SNAPSHOT_FIELDS = %w[title transcription xml_transcription source_translation
                       xml_translation status transcription_json ai_draft_used].freeze
  TEXT_FIELDS = %w[transcription xml_transcription source_translation xml_translation
                  transcription_json].freeze

  def initialize(apply: false, repair_deeds: false, audit:)
    @apply = apply
    @repair_deeds = repair_deeds
    @audit = audit
  end

  def repair(page)
    page.with_lock do
      manifest = page.work.sc_manifest
      return :not_contentdm unless manifest && ContentdmTranslator.iiif_manifest_is_cdm?(manifest.at_id)
      return :ocr if page.work.ocr_correction

      versions = page.page_versions.reorder(:page_version, :id).to_a
      first, duplicate, human = versions
      return :no_duplicate unless first && duplicate && first.page_version == 0 && duplicate.page_version == 1
      return :content_present unless TEXT_FIELDS.all? { |field| first[field].blank? && duplicate[field].blank? }
      return :different_snapshot unless SNAPSHOT_FIELDS.all? { |field| first[field] == duplicate[field] }
      return :not_import_owner unless [first.user_id, duplicate.user_id].all? { |id| id == page.work.owner_user_id }
      return :outside_import_window unless [first, duplicate].all? do |version|
        version.created_on && page.created_on &&
          version.created_on.between?(page.created_on, page.created_on + 1.minute)
      end
      return :flagged if duplicate.flags.exists?
      return :unexpected_sequence unless versions.map(&:page_version) == (0...versions.size).to_a
      return :unexpected_pointer unless page.page_version_id == versions.last.id

      # Uses index_deeds_on_page_id; never scans deeds globally. Deeds cannot
      # be joined directly to versions, so ambiguous timestamp matches are skipped.
      deed_scope = Deed.where(page_id: page.id).order(:created_at, :id)
      deed_scope = deed_scope.lock if @apply
      deeds = deed_scope.to_a
      return :early_activity if deeds.any? { |deed| deed.created_at <= duplicate.created_on }
      deed = transcription_deed(page, human, versions[3], deeds)

      record = {
        event: 'planned', apply: @apply, page_id: page.id, work_id: page.work_id,
        deleted_version: duplicate.attributes,
        version_numbers: versions.drop(2).map { |version| [version.id, version.page_version] },
        previous_page_version_id: page.page_version_id,
        deed: deed&.attributes, repair_deed: @repair_deeds && deed.present?
      }
      write_audit(record)
      return :candidate unless @apply

      page.update_columns(page_version_id: first.id) if page.page_version_id == duplicate.id
      duplicate.delete
      PageVersion.where(page_id: page.id).where('page_version > 1')
                 .update_all('page_version = page_version - 1')
      if @repair_deeds && deed
        deed.deed_type = DeedType::PAGE_TRANSCRIPTION
        deed.calculate_prerender
        deed.calculate_prerender_mailer
        # Preserve activity timestamps/publicity and bypass callbacks which would
        # move a collection/work's most-recent activity backwards.
        deed.update_columns(deed_type: deed.deed_type, prerender: deed.prerender,
                            prerender_mailer: deed.prerender_mailer)
      end
      :repaired
    end
  end

  private

  def transcription_deed(page, human, following, deeds)
    return unless human && human.page_version == 2 && human.transcription.present?
    return if human.created_on.nil? || deeds.any? { |deed| deed.deed_type == DeedType::PAGE_TRANSCRIPTION }
    candidates = deeds.select do |deed|
      deed.deed_type == DeedType::PAGE_EDIT && deed.user_id == human.user_id &&
        deed.work_id == page.work_id && deed.collection_id == page.work.collection_id &&
        deed.created_at.between?(human.created_on, human.created_on + 5.seconds) &&
        (!following || (following.created_on && deed.created_at < following.created_on))
    end
    candidates.one? ? candidates.first : nil
  end

  def write_audit(record)
    @audit.puts(record.to_json)
    @audit.flush
    @audit.fsync if @audit.respond_to?(:fsync)
  end
end
