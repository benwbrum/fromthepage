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
    ensure_active_storage_image!

    filename = @page.image.filename.to_s
    content_type = @page.image.content_type

    downloaded = @page.image.download
    image = Magick::Image.from_blob(downloaded).first

    # NOTE: This is needed to `bake` the rotation
    # metadata into the image instead of rotate only
    # applying to exif metadata. Our exports will not
    # rotate properly unless we do this.
    image = image.auto_orient
    image.strip!
    image = image.rotate(@orientation.to_i)

    @page.image.purge

    @page.image.attach(
      io: StringIO.new(image.to_blob),
      filename: filename,
      content_type: content_type
    )
  end

  private

  def ensure_active_storage_image!
    return if @page.image.attached?

    legacy_path = File.join(
      Rails.root,
      'public',
      @page.base_image.sub(%r{\A.*public/}, '')
    )

    return unless File.exist?(legacy_path)
    extension = File.extname(legacy_path).downcase

    content_type =
      case extension
      when '.jpg', '.jpeg'
        'image/jpeg'
      when '.png'
        'image/png'
      when '.gif'
        'image/gif'
      when '.webp'
        'image/webp'
      else
        'application/octet-stream'
      end

    File.open(legacy_path) do |file|
      @page.image.attach(
        io: file,
        filename: File.basename(legacy_path),
        content_type: content_type
      )
    end
  end
end
