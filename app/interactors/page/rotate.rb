class Page::Rotate < ApplicationInteractor
  attr_accessor :page

  include Page::Lib::Common
  include ImageHelper

  def initialize(page:, orientation:)
    @page        = page
    @orientation = orientation

    super
  end

  def perform
    0.upto(@page.shrink_factor) do |i|
      rotate_file(@page.scaled_image(i), @orientation)
    end
    assign_dimensions
  end
end
