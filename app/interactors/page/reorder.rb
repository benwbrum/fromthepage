class Page::Reorder
  include Interactor

  def initialize(page:, direction:)
    @page      = page
    @direction = direction

    super
  end

  def call
    @direction == 'up' ? @page.move_higher : @page.move_lower

    context
  end
end
