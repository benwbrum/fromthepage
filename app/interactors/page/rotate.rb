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
    if @page.image.attached?
      filename = @page.image.filename.to_s
      content_type = @page.image.content_type

      downloaded = @page.image.download
      image = MiniMagick::Image.read(downloaded)

      # NOTE: This is needed to `bake` the rotation
      # metadata into the image instead of rotate only
      # applying to exif metadata. Our exports will not
      # rotate properly unless we do this.
      image = image.auto_orient
      image.strip
      image.rotate(@orientation.to_i)

      @page.image.purge

      @page.image.attach(
        io: StringIO.new(image.to_blob),
        filename: filename,
        content_type: content_type
      )
    else
      # TODO: Deprecate this once move to active_storage is complete
      0.upto(@page.shrink_factor) do |i|
        rotate_file(@page.scaled_image(i), @orientation)
      end
      assign_dimensions
    end
  end
end
