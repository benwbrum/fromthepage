class Page::Rotate
  include Page::Lib::Common
  include ImageHelper
  include Interactor

  def initialize(page:, orientation: 0)
    @page        = page
    @orientation = orientation

    super
  end

  def call
    0.upto(@page.shrink_factor) do |i|
      rotate_file(@page.scaled_image(i), @orientation)
    end
    assign_dimensions

    context
  end
end
