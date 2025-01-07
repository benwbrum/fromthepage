class DocumentSet::Update
  include Interactor

  def initialize(document_set:, document_set_params:)
    @document_set        = document_set
    @document_set_params = document_set_params
    @errors              = nil

    super
  end

  def call
    @document_set.attributes = @document_set_params
    @document_set.slug = @document_set.title.parameterize if @document_set_params[:slug].blank?
    context.updated_fields_hash = @document_set.changes.transform_values(&:last)

    unless @document_set.save
      @errors = @document_set.errors.full_messages
      context.errors = @errors
      context.fail!
    end

    context
  end
end
