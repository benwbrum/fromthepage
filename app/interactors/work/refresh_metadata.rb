# frozen_string_literal: true

class Work::RefreshMetadata
  include Interactor

  def initialize(work_ids: nil, batches: 100)
    @all_works      = Work.where(id: work_ids)
    @batches        = batches
    @errors         = []

    super
  end

  def call
    @all_works.in_batches(of: 100).each do |works|
      process_batches(works)
    end

    finalize
  rescue => e
    @errors << "Error: #{e}"
    context.errors = @errors
    context.fail!
  end

  def finalize
    context.errors = @errors
    context
  end

  private

  def process_batches(works)
    works.each do |work|
      next unless work.sc_manifest

      begin
        refresh_metadata(work)
      rescue
        @errors << "Failed to refresh metadata for #{work.slug}"
        context.fail!
      end
    end
  end

  def refresh_metadata(work)
    manifest = JSON.parse URI.open(work.sc_manifest.at_id).read
    work.original_metadata = manifest['metadata'].to_json
    work.save
  end
end
