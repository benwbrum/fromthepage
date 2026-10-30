class SubjectHeadings::CreateSampleSet < ApplicationInteractor
  TITLE = 'Subject Heading Sample Set'.freeze
  DESCRIPTION = 'Documents chosen automatically to represent the variety of this collection, ' \
                'for reviewing and cataloging AI subject heading suggestions.'.freeze
  SIZE = 20
  POOL_SIZE = 1_000
  MIN_TEXT_LENGTH = 200
  HUMAN_STATUSES = [:incomplete, :transcribed, :indexed, :needs_review].freeze

  attr_accessor :document_set

  # Creates a private document set of transcribed works that represent the variety of the collection,
  # chosen from their transcripts alone (see SubjectHeadings::Lib::VariedSelection). Works are drawn from
  # the whole collection whether their text is human or AI transcription, so the sample isn't skewed
  # toward whatever volunteers happened to transcribe first.
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

  # [work, text] pairs for a random POOL_SIZE of the works with human or AI transcription
  def candidate_works
    pages = Page.where(work_id: @collection.works.select(:id))
    ai_pages = AiTranscription.where(page_id: pages.select(:id)).merge(AiTranscription.status_finished.or(AiTranscription.alto))
    pages_with_text = pages.where(status: HUMAN_STATUSES).or(pages.where(id: ai_pages.select(:page_id)))
    ids = @collection.works.where(id: pages_with_text.select(:work_id)).pluck(:id)
                     .sample(POOL_SIZE, random: Random.new(@collection.id))

    works = Work.where(id: ids).includes(:pages).order(:id).to_a
    Page.preload_plaintext_for_ai(works.flat_map(&:pages))

    works.filter_map do |work|
      text = work.plaintext_for_ai
      [work, "#{work.title}\n#{text}"] if text.length >= MIN_TEXT_LENGTH
    end
  end
end
