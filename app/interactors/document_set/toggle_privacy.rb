class DocumentSet::TogglePrivacy
  include Interactor

  def initialize(document_set:)
    @document_set = document_set

    super
  end

  def call
    current_privacy = @document_set.is_public
    @document_set.is_public = !current_privacy

    @document_set.save!

    context
  end
end
