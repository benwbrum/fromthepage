class ApplicationInteractor

  attr_reader :context

  def initialize(context = {})
    @context = Interactor::Context.build(context)
  end

  def call
    perform

    self
  rescue Interactor::Failure
    self
  end

  def success?
    context.success?
  end

  def message
    context.message
  end

end
