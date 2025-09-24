class Collection::Blankout < ApplicationInteractor
  attr_accessor :collection

  BATCH_SIZE = 1000

  def initialize(collection:)
    @collection = collection

    super
  end

  def perform
    @works = Work.where(collection_id: @collection.id)
    @pages = Page.where(work_id: @works.select(:id))
    @page_versions = PageVersion.where(page_id: @pages.select(:id))

    destroy_items
    blankout_relevant_columns
  end

  private

  def destroy_items
    articles = Article.where(collection_id: @collection.id)
    deeds = Deed.where(page_id: @pages.select(:id)).or(Deed.where(article_id: articles.select(:id)))
    categories = Category.where(collection_id: @collection.id).where.not(title: [ 'People', 'Places' ])
    notes = Note.where(page_id: @pages.select(:id))
    page_article_links = PageArticleLink.where(page_id: @pages.select(:id))

    deeds.destroy_all
    articles.destroy_all
    categories.destroy_all
    notes.destroy_all
    page_article_links.destroy_all
  end

  def blankout_relevant_columns
    @works.each do |work|
      work.update_columns(transcription_version: 0)
    end

    @pages.each do |page|
      page.page_versions.destroy_all
      page.update_columns(
        source_text: nil,
        created_on: Time.now,
        lock_version: 0,
        xml_text: nil,
        status: Page.statuses[:new],
        source_translation: nil,
        xml_translation: nil,
        translation_status: Page.translation_statuses[:new],
        search_text: "\n\n\n\n"
      )
      page.save!
    end

    @page_versions.each do |page_version|
      page_version.user_id = @collection.owner_user_id
      page_version.save!
    end
  end
end
