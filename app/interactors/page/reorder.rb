class Page::Reorder < ApplicationInteractor
  def initialize(page:, direction:)
    @page      = page
    @direction = direction

    super
  end

  def perform
    @direction == 'up' ? @page.move_higher : @page.move_lower
  end
end
