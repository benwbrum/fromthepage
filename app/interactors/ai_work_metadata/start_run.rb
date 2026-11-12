# Launches AI metadata drafting from the collection AI settings tab.
#
# - sample:    drafts the collection's sample set (SubjectHeadings::CreateSampleSet) for the owner to review
# - remainder: drafts every work outside the sample, with the reviewed sample works as prompt examples
# - all:       drafts every work without examples (the owner skipped the sample)
#
# Drafts are written from AI transcriptions, so pages without one are AI-transcribed first. The run
# waits (AiWorkMetadata::StartRunJob) until the collection's transcription has finished, then chooses
# its works and queues the drafts (AiWorkMetadata::StartRun.begin!).
class AiWorkMetadata::StartRun < ApplicationInteractor
  include AiWorkMetadata::Lib::Common

  attr_accessor :run

  def initialize(collection:, user:, kind:)
    @collection = collection
    @user = user
    @kind = kind.to_s

    super
  end

  def perform
    check_user_permission
    raise ArgumentError, "Unknown AI metadata run: #{@kind}" unless AiWorkMetadataRun::KINDS.include?(@kind)
    raise ArgumentError, 'Collection has no metadata fields configured' unless @collection.metadata_fields.exists?
    raise ArgumentError, 'There are no works to draft' unless @collection.works.exists?
    raise ArgumentError, 'AI metadata drafting is already waiting for AI transcription' if @collection.ai_work_metadata_runs.where(started_at: nil).exists?

    example_ids = @kind == 'remainder' ? self.class.reviewed_sample_work_ids(@collection) : []
    @run = @collection.ai_work_metadata_runs.create!(kind: @kind, user: @user, example_work_ids: example_ids)

    if AiWorkMetadata::Lib::CollectionTranscription.complete?(@collection)
      self.class.begin!(@run)
    else
      AiWorkMetadata::Lib::CollectionTranscription.launch!(@collection, @user)
      AiWorkMetadata::StartRunJob.perform_later(user_id: @user.id, run_id: @run.id)
    end
  end

  # Chooses the run's works and queues their drafts. Called once the collection is transcribed.
  def self.begin!(run)
    run.with_lock do
      return false unless run.waiting?

      collection = run.collection
      work_ids = work_ids_for(run)
      if work_ids.any?
        drafts = AiWorkMetadata::BulkCreate.new(collection: collection, user: run.user, scope: { work_ids: work_ids },
                                                model: run.sample? ? AiWorkMetadata::SUBJECT_HEADING_MODEL : nil, run: run).call
        raise drafts.full_errors unless drafts.success?

        AiWorkMetadata::BulkGenerateJob.perform_later(user_id: run.user.id, collection_id: collection.id,
                                                      scope: { work_ids: work_ids })
      end
      run.update!(started_at: Time.current)
    end
    true
  end

  # The collection's sample set, or nil
  def self.sample_set(collection)
    collection.document_sets.find_by(title: SubjectHeadings::CreateSampleSet::TITLE)
  end

  # Works outside the sample that no remainder or skip-the-sample run has drafted yet,
  # including works added after earlier runs
  def self.remaining_work_ids(collection)
    bulk_runs = collection.ai_work_metadata_runs.where(kind: %w[remainder all])
    drafted = AiWorkMetadata.where(ai_work_metadata_run_id: bulk_runs.select(:id)).select(:work_id)
    collection.works.where.not(id: sample_set(collection)&.work_ids || []).where.not(id: drafted).pluck(:id)
  end

  # Sample works whose AI draft the owner has reviewed
  def self.reviewed_sample_work_ids(collection)
    set = sample_set(collection)
    return [] unless set

    AiWorkMetadata.where(work_id: set.work_ids).where.not(reviewed_at: nil).distinct.pluck(:work_id)
  end

  def self.work_ids_for(run)
    collection = run.collection
    case run.kind
    when 'sample' then sample_work_ids(collection, run.user)
    when 'remainder' then remaining_work_ids(collection)
    else collection.works.pluck(:id)
    end
  end

  def self.sample_work_ids(collection, user)
    set = sample_set(collection)
    unless set
      created = SubjectHeadings::CreateSampleSet.new(collection: collection, user: user).call
      raise created.full_errors unless created.success?

      set = created.document_set
    end
    set.work_ids
  end
end
