module Page::Lib::Common

  def process_uploaded_file(image_file)
    unless Page::ACCEPTED_FILE_TYPES.include?(image_file.content_type)
      error_msg = I18n.t('errors.unsupported_file_type')
      @page.errors.add(:base_image, error_msg)
      raise ArgumentError, error_msg
    end

    filename = "#{Rails.root}/public/images/working/upload/#{@page.id}.jpg"

    dirname = File.dirname(filename)
    FileUtils.mkdir_p(dirname) unless Dir.exist? dirname

    FileUtils.mv(image_file.tempfile, filename)
    FileUtils.chmod('u=wr,go=r', filename)
    @page.base_image = filename
    @page.shrink_factor = 0
    assign_dimensions
  rescue StandardError => e
    context.errors = e.message
    context.fail!
    raise ActiveRecord::Rollback
  end

  def assign_dimensions
    image = Magick::ImageList.new(@page.base_image)
    @page.base_width = image.columns
    @page.base_height = image.rows
    @page.save!
  end

end
