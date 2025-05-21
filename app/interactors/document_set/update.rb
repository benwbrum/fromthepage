class DocumentSet::Update < ApplicationInteractor
  attr_accessor :document_set

  def initialize(document_set:, document_set_params:)
    @document_set        = document_set
    @document_set_params = document_set_params

    super
  end

  def perform
    toggle_privacy

    @document_set.attributes = @document_set_params
    @document_set.slug = @document_set.title.parameterize if @document_set_params[:slug].blank?

    @document_set.save!

    return unless @document_set.saved_change_to_visibility?

    Elasticsearch::Collection::SyncJob.perform_later(collection_id: @document_set.id, type: :document_set)
  end

  private

  def toggle_privacy
    return unless @document_set_params[:visibility].present?

    visibility = DocumentSet.visibilities[@document_set_params[:visibility]] || DocumentSet.visibilities[:public]
    @document_set_params[:visibility] = visibility
  end
end
