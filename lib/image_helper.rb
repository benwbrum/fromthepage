#require_dependency "user"
require 'RMagick'
include Magick

module ImageHelper 
  
  protected

  def safe_update(image, attributes)
    begin
      if @logger
        @logger.debug("ImageHelper updating image #{image.id} with #{attributes.inspect}")
      end
      image.update_attributes(attributes)
      if @logger
        @logger.debug("ImageHelper updated  image #{image.id}")
      end
    rescue ActiveRecord::StaleObjectError
      if defined? logger
        logger.debug("  StaleObjectError on image #{image.id} with #{attributes.inspect}")
      end 
      if @logger
        @logger.debug("  StaleObjectError on image #{image.id} with #{attributes.inspect}")
      end
      image = TitledImage.find(image.id)
      safe_update(image, attributes)
    end
  end

  def shrink_file(input_file, output_file, factor) 
    RAILS_DEFAULT_LOGGER.debug("DEBUG ImageHelper if=#{input_file} of=#{output_file}")
    orig = Magick::ImageList.new(input_file)
    fraction = 1.to_f / (2.to_f ** factor)
    smaller = orig.resize(fraction)
    smaller.write(output_file)
    smaller = nil
    orig = nil
    GC.start
  end

  def shrink(image, factor) 
    shrunk_file = image.shrunk_file(factor)
    shrink_file(image.original_file, shrunk_file, factor)
  end

  def shrink_to_sextodecimo(image)
    shrink(image, 2)
    safe_update(image, { :shrink_completed => true })
  end

  def rotate_file(file, orientation) 
    smaller = Magick::ImageList.new(file)
    smaller.rotate!(orientation)
    smaller.write(file)
    smaller = nil
    GC.start
  end

  def rotate(image, orientation, factor)
    if @logger
      @logger.debug("ImageHelper rotate(#{image.id}, #{orientation}, #{factor})")
    end 
    if ( 0 != orientation) 
      file = image.shrunk_file(factor)
      if @logger
        @logger.debug("ImageHelper rotating #{file}")
      end
      rotate_file(file, orientation)
    end
  end
  
  # This may now be dead code
  def rotate_sextodecimo(image, orientation)
    rotate(image, orientation, 2)
    safe_update(image, { :rotate_completed => true })
  end

  def crop_sextodecimo(image, start_y, height)
    orig = Magick::ImageList.new(image.shrunk_file)
    width = orig.columns
    crop = orig.crop(0, start_y, width, height)
    crop.write(image.crop_file)    
    RAILS_DEFAULT_LOGGER.debug("DEBUG cropping #{image.shrunk_file} to #{image.crop_file}")
    orig = nil
    crop = nil
    GC.start
##    image.update_attribute(:crop_completed, true)    
##    TitledImage.transaction(image) do
#      image = TitledImage.find(image.id)
#      image.crop_completed = true
#      image.save!
##    end
    safe_update(image, { :crop_completed => true })
  end

end
