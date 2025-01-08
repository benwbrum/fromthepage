class Work::Metadata::Refresh < ApplicationInteractor

  attr_reader :errors

  def initialize(work_ids: nil, batches: 100)
    @all_works      = Work.where(id: work_ids)
    @batches        = batches
    @errors         = []

    super
  end

  def perform
    @all_works.in_batches(of: 100).each do |works|
      process_batches(works)
    end

    # :nocov:
  rescue StandardError => e
    @errors << "Error: #{e}"
    context.fail!
    # :nocov: end
  end

  private

  def process_batches(works)
    works.each do |work|
      next unless work.sc_manifest

      begin
        refresh_metadata(work)

        # :nocov:
      rescue StandardError => _e
        @errors << "Failed to refresh metadata for #{work.slug}"
        context.fail!
        # :nocov: end
      end
    end
  end

  def refresh_metadata(work)
    manifest = JSON.parse URI.open(work.sc_manifest.at_id).read
    work.original_metadata = manifest['metadata'].to_json
    work.save
  end
end
