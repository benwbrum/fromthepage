class SubjectHeadings::CreateSampleSet < ApplicationInteractor
  TITLE = 'Subject Heading Sample Set'.freeze
  DESCRIPTION = 'Documents chosen automatically to represent the variety of this collection, ' \
                'for reviewing and cataloging AI subject heading suggestions.'.freeze
  SIZE = 20
  POOL_SIZE = 1_000
  MIN_TEXT_LENGTH = 200
  TRANSCRIBED_STATUSES = [:transcribed, :indexed, :needs_review].freeze
  UNFINISHED_STATUSES = [:new, :incomplete, nil].freeze

  attr_accessor :document_set

  # Creates a private document set of transcribed works that represent the variety of the collection,
  # chosen from their transcripts alone (see SubjectHeadings::Lib::VariedSelection).
  #
  # @params collection: required
  # @params user: required
  #   - User must be admin OR like_owner? of the collection
  # @params size: optional
  #   - Number of works in the set, defaults to SIZE
  def initialize(collection:, user:, size: SIZE)
    @collection = collection
    @user = user
    @size = size

    super
  end

  def perform
    check_user_permission
    raise ArgumentError, "Collection already has a \"#{TITLE}\" document set" if @collection.document_sets.exists?(title: TITLE)

    candidates = candidate_works
    raise ArgumentError, 'Collection has no transcribed works to sample' if candidates.empty?

    chosen = SubjectHeadings::Lib::VariedSelection
             .new(candidates.map(&:last), count: @size, seed: @collection.id)
             .indexes
             .map { |i| candidates[i].first }

    DocumentSet.transaction do
      @collection.update!(supports_document_sets: true) unless @collection.supports_document_sets
      @document_set = DocumentSet.create!(
        title: TITLE,
        description: DESCRIPTION,
        collection: @collection,
        owner: @collection.owner,
        visibility: :private
      )
      @document_set.work_ids = chosen.map(&:id)
      @document_set.save!
    end
  end

  private

  def check_user_permission
    return if @user.admin? || @user.like_owner?(@collection)

    raise ArgumentError, 'User has no permission to create a sample set for this collection'
  end

  # [work, text] pairs for up to POOL_SIZE transcribed works, preferring fully transcribed ones
  def candidate_works
    random = Random.new(@collection.id)
    work_ids = @collection.works.select(:id)
    transcribed = @collection.works.where(id: Page.where(work_id: work_ids, status: TRANSCRIBED_STATUSES).select(:work_id))
    unfinished = Page.where(work_id: work_ids, status: UNFINISHED_STATUSES).select(:work_id)

    ids = transcribed.where.not(id: unfinished).pluck(:id).sample(POOL_SIZE, random: random)
    ids += transcribed.where(id: unfinished).pluck(:id).sample(POOL_SIZE - ids.size, random: random) if ids.size < POOL_SIZE

    Work.where(id: ids).includes(:pages).order(:id).filter_map do |work|
      text = work.verbatim_transcription_plaintext.to_s
      [work, "#{work.title}\n#{text}"] if text.length >= MIN_TEXT_LENGTH
    end
  end
end
