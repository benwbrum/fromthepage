# AI metadata drafts are written from each work's AI transcription, so the collection's pages are
# AI-transcribed before any drafting starts. Pages whose transcription failed don't hold drafting up;
# they are listed (with a retry) in the AI Transcription section.
module AiWorkMetadata::Lib::CollectionTranscription
  module_function

  # Pages that have never been sent for AI transcription
  def untranscribed_pages(collection)
    pages(collection).where.not(id: AiTranscription.where(page_id: pages(collection).select(:id)).where.not(status: :new).select(:page_id))
  end

  def in_progress?(collection)
    latest(collection).where(status: %w[new queued processing]).exists?
  end

  def complete?(collection)
    !in_progress?(collection) && !untranscribed_pages(collection).exists?
  end

  # Launches AI transcription for pages without it, as "Create AI drafts for pages without them" does
  def launch!(collection, user)
    return false unless untranscribed_pages(collection).exists?

    result = AiTranscription::BulkCreate.new(collection: collection, user: user).call
    raise result.full_errors unless result.success?

    AiTranscription::BulkGenerateJob.perform_later(collection_id: collection.id, user_id: user.id)
    true
  end

  def pages(collection)
    Page.joins(:work).where(works: { collection_id: collection.id }).reorder(nil)
  end

  def latest(collection)
    latest_ids = AiTranscription.where(page_id: pages(collection).select(:id)).select('MAX(id) AS id').group(:page_id)
    AiTranscription.joins("INNER JOIN (#{latest_ids.to_sql}) latest ON latest.id = ai_transcriptions.id")
  end
end
