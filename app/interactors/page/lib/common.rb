module Page::Lib::Common
  def process_uploaded_file(image_file)
    unless Page::ACCEPTED_FILE_TYPES.include?(image_file.content_type)
      error_msg = I18n.t('errors.unsupported_file_type')
      @page.errors.add(:base_image, error_msg)
      raise StandardError, error_msg
    end

    @page.image.attach(image_file)

    @page.save!
  rescue StandardError => e
    context.errors = e.message
    context.fail!
  end
end
