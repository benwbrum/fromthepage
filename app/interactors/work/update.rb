class Work::Update < ApplicationInteractor
  attr_accessor :work, :collection, :original_collection_id

  def initialize(work:, work_params:)
    @work        = work
    @work_params = work_params

    super
  end

  def perform
    @original_collection_id = @work.collection_id
    @collection = Collection.find_by(id: @work_params[:collection_id])

    if @collection.nil?
      @work.errors.add(:collection_id, :blank)
      context.fail!
    end

    params_convention = normalize_conventions_string(@work_params[:transcription_conventions])
    collection_convention = normalize_conventions_string(@collection.transcription_conventions)

    @work_params = @work_params.merge(transcription_conventions: nil) if params_convention == collection_convention
    @work.attributes = @work_params

    @work.slug = @work.title.parameterize if @work_params[:slug].blank?

    if @work.save
      change_collection if @original_collection_id != @collection.id
    else
      context.fail!
    end
  end

  private

  def normalize_conventions_string(input)
    input
      .gsub(/\r\n?/, "\n")
      .gsub(/\s+/, ' ')
      .strip
  end

  def change_collection
    @work.update_deed_collection

    return if @work.articles.blank?

    pages = @work.pages

    # Delete page_article_links for this work
    PageArticleLink.where(page_id: pages.select(:id)).destroy_all

    # Remove links from pages in this work
    pages.each do |p|
      p.remove_transcription_links(p.source_text) unless p.source_text.nil?
      p.remove_translation_links(p.source_translation) unless p.source_translation.nil?
    end

    @work.save!
  end
end
