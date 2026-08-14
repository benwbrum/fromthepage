# frozen_string_literal: true

# require_dependency "user"
require 'fileutils'
require 'rmagick'
require 'zip'
require 'shellwords'
include Magick

module ImageHelper
  #############################
  # Code for new zoom feature
  #############################

  def self.unzip_file(file, destination)
    print "upzip_file(#{file})\n"

    destination = File.expand_path(destination)

    Zip::File.open(file) do |zip_file|
      entries = zip_file.map do |entry|
        entry_name = entry.name
        raise Zip::EntryNameError, 'ZIP entry contains a null byte' if entry_name.include?("\0")

        # ZIP uses forward slashes, but treat backslashes as separators too so
        # archives made on Windows cannot disguise an absolute or traversal path.
        normalized_name = entry_name.tr('\\', '/')
        components = normalized_name.split('/', -1)
        if normalized_name.start_with?('/') || normalized_name.match?(/\A[A-Za-z]:/) ||
           components.include?('..')
          raise Zip::EntryNameError, "unsafe ZIP entry path: #{entry_name.inspect}"
        end

        outfile = File.expand_path(normalized_name, destination)
        unless outfile.start_with?("#{destination}#{File::SEPARATOR}")
          raise Zip::EntryNameError, "ZIP entry is outside destination: #{entry_name.inspect}"
        end

        unless entry.directory? || entry.ftype == :file
          raise Zip::EntryNameError, "unsupported ZIP entry type #{entry.ftype}: #{entry_name.inspect}"
        end

        [entry, outfile]
      end

      # Do not create anything until every entry in the archive has passed
      # validation, so a bad entry cannot leave a partially extracted archive.
      entries.each do |entry, outfile|
        directory = entry.directory? ? outfile : File.dirname(outfile)
        prepare_zip_directory(directory, destination, create: false)
      end
      prepare_zip_directory(destination, destination, create: true)
      entries.each do |entry, outfile|
        if entry.directory?
          prepare_zip_directory(outfile, destination, create: true)
          next
        end

        prepare_zip_directory(File.dirname(outfile), destination, create: true)

        print "\textracting #{outfile}\n"
        flags = File::WRONLY | File::CREAT | File::EXCL
        flags |= File::NOFOLLOW if defined?(File::NOFOLLOW)
        File.open(outfile, flags, 0o600) do |output|
          entry.get_input_stream { |input| IO.copy_stream(input, output) }
        end
      end
    end
  end

  def self.prepare_zip_directory(directory, destination, create:)
    relative = directory.delete_prefix(destination).delete_prefix(File::SEPARATOR)
    current = destination
    paths = [destination]
    paths.concat(relative.split(File::SEPARATOR).map { |part| current = File.join(current, part) }) unless relative.empty?

    paths.each do |path|
      if File.exist?(path) || File.symlink?(path)
        raise Zip::EntryNameError, "ZIP extraction path contains a symlink: #{path}" if File.symlink?(path)
        raise Zip::EntryNameError, "ZIP extraction path is not a directory: #{path}" unless File.directory?(path)
      elsif create
        Dir.mkdir(path, 0o700)
      end
    end
  end
  private_class_method :prepare_zip_directory

  def self.calculate_page_size_and_dpi(filename)
    # some PDFs have page sizes so big that our 300x300 DPI creates images wider than the max 16000
    raw_page_size = `pdfinfo #{Shellwords.escape(filename)} | grep "Page size"`.gsub(/Page size:\s+/, '').gsub(' pts',
                                                                                                               '').chomp
    dpi = 300
    pixel_dim = raw_page_size.split(' x ').map { |e| e.to_f / 72 * dpi }
    if pixel_dim.max >= 16_000
      dpi = 150
      pixel_dim = raw_page_size.split(' x ').map { |e| e.to_f / 72 * dpi }
      dpi = 72 if pixel_dim.max >= 16_000
    end
    { raw_page_size: raw_page_size, dpi: dpi }
  end

  def self.extract_pdf(filename, ocr = false)
    pattern = Regexp.new("#{File.extname(filename)}$")
    destination = filename.gsub(pattern, '')
    FileUtils.mkdir(destination) unless File.exist?(destination)
    pattern = File.join(destination, 'page_%04d.jpg')

    page_info = calculate_page_size_and_dpi(filename)
    dpi = page_info[:dpi]

    gs = "gs -r#{dpi}x#{dpi} -dJPEGQ=30 -o '#{pattern}' -sDEVICE=jpeg #{Shellwords.escape(filename)}"
    print "\t\t#{gs}\n"
    system(gs)

    if ocr
      # now extract OCR text
      pattern = File.join(destination, 'page_%04d.txt')
      page_count = Dir.glob(File.join(destination, '*.jpg')).count
      1.upto(page_count) do |page_num|
        output_file = pattern % page_num
        pdftotext = "pdftotext -f #{page_num} -l #{page_num} #{Shellwords.escape(filename)} #{Shellwords.escape(output_file)}"
        print "\t\t#{pdftotext}\n"
        system(pdftotext)
      end
    end

    destination
  end

  def self.compress_file(filename)
    p "processing #{filename}"
    if File.extname(filename).match(/[Pp][Dd][Ff]/)
      dirname = extract_pdf(filename)
      compress_files_in_dir(dirname)
    else
      # maybe it's an image file
      compress_image(filename)
    end
  end

  MAX_FILE_SIZE = 2_000_000

  def self.compress_files_in_dir(dirname)
    files = Dir.glob(File.join(dirname, '*.*'))
    files.each { |filename| compress_file(filename) }
  end

  def self.compress_image(filename)
    return unless needs_compression?(filename)

    extension = File.extname(filename)
    working_file = File.join(File.dirname(filename), "resizing.#{extension}")
    9.downto(2).each do |decile|
      GC.start
      percent = decile * 10
      compressed = Magick::ImageList.new(filename)
      compressed.write(working_file) { |options| options.quality = percent }
      p "Compressed file is now #{File.size(working_file)} at quality #{percent}"

      unless needs_compression? working_file
        print "compressed.write('#{filename}')  { self.quality = #{percent} }"
        break # we're done here
      end
    end
    File.unlink(filename)
    FileUtils.cp(working_file, filename)
    File.unlink(working_file)
  end

  def self.convert_tiff(filename)
    original = Magick::ImageList.new(filename)
    new_file = File.join(File.dirname(filename), "#{File.basename(filename, '.*')}.jpg")
    print "Converted file path is #{new_file}"
    converted = original.write(new_file.to_s)
    # Remove the original TIFF file to prevent duplicate pages during ingest
    File.delete(filename) if File.exist?(filename)
    print ' and removed original TIFF file'
    converted
  end

  def self.needs_compression?(filename)
    File.size(filename) > MAX_FILE_SIZE
  end

  #############################
  # Code for old zoom feature
  #############################

  protected

  def safe_update(image, attributes)
    @logger&.debug("ImageHelper updating image #{image.id} with #{attributes.inspect}")
    image.update(attributes)
    @logger&.debug("ImageHelper updated  image #{image.id}")
  rescue ActiveRecord::StaleObjectError
    if defined? logger
      logger.debug("  StaleObjectError on image #{image.id} with #{attributes.inspect}")
    end
    @logger&.debug("  StaleObjectError on image #{image.id} with #{attributes.inspect}")
    image = TitledImage.find(image.id)
    safe_update(image, attributes)
  end

  def shrink_file(input_file, output_file, factor)
    Rails.logger.debug("DEBUG ImageHelper if=#{input_file} of=#{output_file}")
    orig = Magick::ImageList.new(input_file)
    fraction = 1.to_f / (2.to_f**factor)
    smaller = orig.resize(fraction)
    smaller.write(output_file)
    GC.start
  end

  def shrink(image, factor)
    shrunk_file = image.shrunk_file(factor)
    shrink_file(image.original_file, shrunk_file, factor)
  end

  def shrink_to_sextodecimo(image)
    shrink(image, 2)
    safe_update(image, { shrink_completed: true })
  end

  def rotate_file(file, orientation)
    smaller = Magick::ImageList.new(file)
    smaller.rotate!(orientation)
    smaller.write(file)
    GC.start
  end

  def rotate(image, orientation, factor)
    @logger&.debug("ImageHelper rotate(#{image.id}, #{orientation}, #{factor})")
    return unless orientation != 0

    file = image.shrunk_file(factor)
    @logger&.debug("ImageHelper rotating #{file}")
    rotate_file(file, orientation)
  end

  # This may now be dead code
  def rotate_sextodecimo(image, orientation)
    rotate(image, orientation, 2)
    safe_update(image, { rotate_completed: true })
  end

  def crop_sextodecimo(image, start_y, height)
    orig = Magick::ImageList.new(image.shrunk_file)
    width = orig.columns
    crop = orig.crop(0, start_y, width, height)
    crop.write(image.crop_file)
    Rails.logger.debug("DEBUG cropping #{image.shrunk_file} to #{image.crop_file}")
    GC.start
    ##    image.update_attribute(:crop_completed, true)
    ##    TitledImage.transaction(image) do
    #      image = TitledImage.find(image.id)
    #      image.crop_completed = true
    #      image.save!
    ##    end
    safe_update(image, { crop_completed: true })
  end
end
