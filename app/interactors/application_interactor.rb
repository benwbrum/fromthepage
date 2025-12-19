class ApplicationInteractor
  attr_reader :context, :full_errors

  def initialize(context = {})
    @context = Interactor::Context.build(context)
    @success = true
    @full_errors = nil
  end

  def call
    perform

    self
  rescue StandardError => e
    @success = false
    @full_errors = e

    self
  end

  def success?
    @success
  end

  def message
    context.message
  end
end
