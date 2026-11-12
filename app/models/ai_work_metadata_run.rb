# One launch of AI metadata drafting from the collection AI settings tab.
#
# - sample:    drafts the collection's sample set (SubjectHeadings::CreateSampleSet) for the owner to review
# - remainder: drafts every work outside the sample, using the reviewed sample works as prompt examples
# - all:       drafts every work without examples (the owner skipped the sample)
#
# Drafts need an AI transcription of every page, so a run first waits for the collection's AI
# transcription to finish (see AiWorkMetadata::StartRunJob). started_at is set once its drafts are queued.
class AiWorkMetadataRun < ApplicationRecord
  KINDS = %w[sample remainder all].freeze

  belongs_to :collection
  belongs_to :user, optional: true
  has_many :ai_work_metadata, class_name: 'AiWorkMetadata', dependent: :nullify
  serialize :example_work_ids, coder: JSON

  validates :kind, inclusion: { in: KINDS }

  KINDS.each do |kind|
    define_method(:"#{kind}?") { self.kind == kind }
  end

  def example_work_ids
    super || []
  end

  def examples
    @examples ||= AiWorkMetadata::Lib::Examples.new(collection: collection, work_ids: example_work_ids)
  end

  # Waiting for the collection's AI transcription before choosing works and drafting
  def waiting?
    started_at.nil?
  end

  # Work counts in the run's four progress states (new = not started, processing = in progress).
  def counts
    statuses = ai_work_metadata.group(:status).count
    { finished: statuses['finished'].to_i, in_progress: statuses['processing'].to_i,
      failed: statuses['error'].to_i, not_started: statuses['new'].to_i }
  end

  def running?
    waiting? || ai_work_metadata.where(status: %w[new processing]).exists?
  end

  def failed_records
    ai_work_metadata.status_error.includes(:work).order(updated_at: :desc).limit(AiWorkMetadata::MAX_FAILED_ERRORS)
  end
end
