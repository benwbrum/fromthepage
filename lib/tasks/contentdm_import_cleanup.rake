require 'contentdm_import_cleanup'

namespace :fromthepage do
  desc 'Dry-run cleanup of duplicate blank CONTENTdm import versions (see docs/contentdm_import_cleanup.md)'
  task cleanup_contentdm_imports: :environment do
    apply = ENV['APPLY'] == 'true'
    repair_deeds = ENV['REPAIR_DEEDS'] == 'true'
    batch_size = Integer(ENV.fetch('BATCH_SIZE', '100'))
    start_id = Integer(ENV.fetch('START_PAGE_ID', '0'))
    pause = Float(ENV.fetch('PAUSE', '0.1'))
    raise ArgumentError, 'BATCH_SIZE must be positive; PAUSE must be nonnegative' unless batch_size.positive? && pause >= 0
    audit_path = ENV.fetch('AUDIT_PATH')
    counts = Hash.new(0)

    # Manifest URL recognition happens in Ruby, using the same predicate as the
    # importer (including older/vanity CONTENTdm URLs).
    pages = Page.joins(work: :sc_manifest).where('pages.id >= ?', start_id)
    pages = pages.where(work_id: Integer(ENV['WORK_ID'])) if ENV['WORK_ID'].present?
    pages = pages.where(works: { collection_id: Integer(ENV['COLLECTION_ID']) }) if ENV['COLLECTION_ID'].present?
    File.open(audit_path, 'a', 0600) do |audit|
      cleaner = ContentdmImportCleanup.new(apply: apply, repair_deeds: repair_deeds, audit: audit)
      pages.find_in_batches(batch_size: batch_size) do |batch|
        batch.each { |page| counts[cleaner.repair(page)] += 1 }
        puts({ last_page_id: batch.last.id, apply: apply, counts: counts }.to_json)
        sleep(pause) if pause.positive?
      end
    end
    puts counts.to_json
  end
end
