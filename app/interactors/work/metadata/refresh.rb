class Work::Metadata::Refresh < ApplicationInteractor
  MAX_RETRIES = 3
  RETRY_DELAYS = [5, 10, 15].freeze
  ERRORS_TO_RETRY = [
    'Net::ReadTimeout',
    '503 Service Unavailable'
  ].freeze

  attr_reader :logs

  def initialize(work_ids: nil, batches: 100)
    @all_works      = Work.where(id: work_ids)
    @batches        = batches
    @logs           = []

    super
  end

  def perform
    @all_works.in_batches(of: @batches).each do |works|
      process_batches(works)
    end
  end

  private

  def process_batches(works)
    works.each do |work|
      next unless work.sc_manifest

      begin
        retries ||= 0
        log("Refreshing metadata for work: #{work.id}")
        refresh_metadata(work)
      rescue StandardError => e
        if ERRORS_TO_RETRY.any? { |msg| e.message.include?(msg) } && retries < MAX_RETRIES
          wait_time = RETRY_DELAYS[retries]
          log("#{e.message} - retrying in #{wait_time}s (attempt #{retries + 1}/#{MAX_RETRIES})")
          sleep(wait_time)
          retries += 1
          retry
        else
          @success = false

          log("Failed to refresh metadata for #{work.slug}")
          log("Error: #{e.message}")
          log("Stacktrace: #{e.backtrace.join("\n")}")
        end
      end
    end
  end

  def refresh_metadata(work)
    manifest = JSON.parse(URI.open(work.sc_manifest.at_id).read)
    work.original_metadata = manifest['metadata'].to_json
    work.save
  end

  def log(text)
    @logs << text
  end
end
