class SearchAttempt::Create < ApplicationInteractor
  attr_accessor :search_attempt, :link

  def initialize(search_attempt_params:, user: nil)
    @search_attempt_params = search_attempt_params
    @user = user

    super
  end

  def perform
    is_owner = @user&.owner

    query = @search_attempt_params[:search]
    work = Work.friendly.find(@search_attempt_params[:work_id], allow_nil: true)
    collection = Collection.friendly.find(@search_attempt_params[:collection_id], allow_nil: true)
    document_set = DocumentSet.friendly.find(@search_attempt_params[:document_set_id], allow_nil: true)

    if work.present?
      search_type = 'work'
    elsif (collection.present? || document_set.present?) && @search_attempt_params[:search_by_title].present?
      query = @search_attempt_params[:search_by_title]
      search_type = 'collection-title'
    elsif collection.present? || document_set.present?
      search_type = 'collection'
    else
      search_type = 'findaproject'
    end

    query = query&.strip

    context.fail! if query.blank?

    @search_attempt = SearchAttempt.create!(
      query: query,
      search_type: search_type,
      work_id: work&.id,
      collection_id: collection&.id,
      document_set_id: document_set&.id,
      user_id: @user&.id,
      owner: is_owner
    )

    @link = @search_attempt.generate_link
  end
end
