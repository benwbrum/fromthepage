module Page::Lib::Common

  def process_uploaded_file(page, image_file)
    filename = "#{Rails.root}/public/images/working/upload/#{page.id}.jpg"

    dirname = File.dirname(filename)
    FileUtils.mkdir_p(dirname) unless Dir.exist? dirname

    FileUtils.mv(image_file.tempfile, filename)
    FileUtils.chmod('u=wr,go=r', filename)
    page.base_image = filename
    page.shrink_factor = 0
    assign_dimensions(page)
  end

  def assign_dimensions(page)
    image = Magick::ImageList.new(page.base_image)
    page.base_width = image.columns
    page.base_height = image.rows
    page.save!
  end

end
