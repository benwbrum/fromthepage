class ApplicationInteractor
  attr_reader :context

  def initialize(context = {})
    @context = Interactor::Context.build(context)
    @success = true
  end

  def call
    perform

    self
  rescue StandardError
    @success = false

    self
  end

  def success?
    @success
  end

  def message
    context.message
  end
end
