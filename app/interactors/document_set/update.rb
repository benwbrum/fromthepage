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
  end

  private

  def toggle_privacy
    return unless @document_set_params[:is_public].present?

    is_public = ActiveRecord::Type::Boolean.new.cast(@document_set_params[:is_public])
    @document_set_params[:is_public] = is_public
  end
end
