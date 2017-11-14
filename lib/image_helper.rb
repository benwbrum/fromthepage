#require_dependency "user"
require 'fileutils'
require 'rmagick'
require 'zip'
include Magick

module ImageHelper
  
  #############################
  # Code for new zoom feature
  #############################

  def self.unzip_file (file, destination)
    print "upzip_file(#{file})\n"
    
    Zip::File.open(file) do |zip_file|
      zip_file.each do |f|
#        f_path=File.join(destination, File.basename(f.name))
        # FileUtils.mkdir_p(File.dirname(destination)) unless Dir.exist? destination
        outfile = File.join(destination, f.name)
        FileUtils.mkdir_p(File.dirname(outfile))
 
        print "\textracting #{outfile}\n"
        zip_file.extract(f, outfile)
      end
    end
    
  end
  
  def self.extract_pdf(filename)
    pattern = Regexp.new(File.extname(filename) + "$")
    destination = filename.gsub(pattern, '')
    FileUtils.mkdir(destination) unless File.exists?(destination)
    pattern = File.join(destination, "page_%04d.jpg")
    gs = "gs -r300x300 -dJPEGQ=30 -o '#{pattern}' -sDEVICE=jpeg '#{filename}'"
    print gs
    system(gs)
    # convert = "convert -density 200 -quality 30 '#{filename}' '#{pattern}'"
    # print("#{convert}\n")
    # system(convert)
    
    destination
  end

  def self.compress_file(filename)
    p "processing #{filename}"
    if File.extname(filename).match /[Pp][Dd][Ff]/
      dirname = extract_pdf(filename)
      compress_files_in_dir(dirname)
    else
      # maybe it's an image file
      compress_image(filename)
    end
  end
      
  
  MAX_FILE_SIZE = 1000000

  def self.compress_files_in_dir(dirname)
    files = Dir.glob(File.join(dirname, "*.*"))
    files.each { |filename| compress_file(filename) }
  end

  def self.compress_image(filename)
    if needs_compression?(filename)
      extension = File.extname(filename)
      working_file = File.join(File.dirname(filename),"resizing.#{extension}")
      9.downto(1).each do |decile|
        GC.start
        percent = decile * 10
        compressed = Magick::ImageList.new(filename)
        compressed.write(working_file) { self.quality = percent}
        p "Compressed file is now #{File.size(working_file)} at quality #{percent}"

        unless needs_compression? working_file
          print "compressed.write('#{filename}')  { self.quality = #{percent} }"
          break #we're done here
        end
      end
      File.unlink(filename)
      FileUtils.cp(working_file, filename)
      File.unlink(working_file)
    end  
  end

  def self.convert_tiff(filename)
    original = Magick::ImageList.new(filename)
    new_file = File.join((File.dirname(filename)), (File.basename(filename, ".*") + ".jpg"))
    print "Converted file path is #{new_file}"
    converted = original.write("#{new_file}")
    return converted
  end

  def self.needs_compression?(filename)
    File.size(filename) > MAX_FILE_SIZE
  end

  #############################
  # Code for old zoom feature
  #############################

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
    Rails.logger.debug("DEBUG ImageHelper if=#{input_file} of=#{output_file}")
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
    Rails.logger.debug("DEBUG cropping #{image.shrunk_file} to #{image.crop_file}")
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
