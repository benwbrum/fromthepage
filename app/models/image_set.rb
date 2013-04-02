class ImageSet < ActiveRecord::Base
  include FileUtils::Verbose
  include Magick
  include ImageHelper
  
  has_many :titled_images, :order => :position
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_user_id"
  
  
  STEP_DIRECTORY_PROCESS = 'directory_process'
  STEP_ORIENTATION_PROCESS = 'orientation_process'
  STEP_SIZE_PROCESS = 'size_process'
  STEP_NUMBER_LOCATION_PROCESS = 'number_location_process'
  STEP_PROCESSING_COMPLETE = 'processing_complete'
  
  
  STATUS_COMPLETE = 'complete'
  STATUS_ERROR = 'error'
  STATUS_RUNNING = 'running'
  
  # tested
  def page_count
    if titled_images == nil
      return 0
    end
    titled_images.size
  end
  
  def summary
    if page_count == 0
      return 'empty'
    end
    desc = ''
    if page_count <= 4
      titled_images.each { |image| desc = "#{desc}, #{image.title}" }
      return desc
    end
    desc += "#{titled_images[0].title}, #{titled_images[1].title} ... #{titled_images[page_count-1].title}, #{titled_images[page_count-2].title}"
    return desc
  end
  
  def sample_image
    self.titled_images[(self.titled_images.length / 3)]   
  end

  
  ##############################################################
  # This is intended to be run inline, and be fairly quick
  ##############################################################
  def directory_setup(source_directory_name)
    # create a working directory
    debug("current directory is #{Dir.getwd}")

    self.step = STEP_DIRECTORY_PROCESS
    self.status = STATUS_RUNNING
    self.save!

    create_new_directory
    populate_titled_images(source_directory_name)
    process_sample_image(source_directory_name)
    
  end    

  def flag_error(message)
    debug(message)
    self.status = STATUS_ERROR
    self.status_message = message
    self.save!
  end

  def create_new_directory
    self.status_message = "creating new directory"
    new_dir_name = File.join(Dir.getwd,
                             "public",
                             "images",
                             "working", 
                             self.id.to_s) 
    if(!Dir.mkdir(new_dir_name))
      flag_error("could not create directory #{new_dir_name}")
    end
    if(!File.chmod(0777, new_dir_name))
      flag_error("could not chmod directory #{new_dir_name}")
    end
    self.path = new_dir_name   
  end

  def populate_titled_images(source_directory_name)
    self.status_message = "populate_titled_images loading image files into database"
    original_files = Dir.glob(File.join(source_directory_name, "*.jpg"))
    original_files.sort!
    original_files.each do |image_filename|
      image = TitledImage.new
      image.original_file = image_filename.gsub(source_directory_name+'/', "")
      self.titled_images << image
    end
    self.save!
    
  end

  def process_sample_image(source_directory_name)
    self.status_message = "processing sample image"

    cp(File.join(source_directory_name, self.sample_image.original_file(true)), "#{self.path}")

    # set default image data
    orig = Magick::ImageList.new(sample_image.original_file)
    self.original_width = orig.columns
    self.original_height = orig.rows
    

    debug("process_sample_image begin shrink #{Time.now}")
    # shrink the sample file to 1:4
    self.status_message = "shrinking sample image"
    shrink_to_sextodecimo(sample_image)
    debug("process_sample_image end   shrink #{Time.now}")

    # spawn a 1:4 shrink of the remaining files
    # set shrinkage -- eventually will be its own workflow
    self.original_to_base_halvings = 2
    self.status = STATUS_COMPLETE
    self.save!
    
  end

  def process_sample_orientation
    self.status_message = "processing sample image"
    if(!sample_image.rotate_completed)
      rotate(sample_image, self.orientation, 0)
      safe_update(sample_image, { :rotate_completed => true })
      shrink_to_sextodecimo(sample_image)
    end #if
        
  end
  
  
  
  def resize_sample_image
    unless File.exists? self.sample_image.shrunk_file
      shrink(sample_image, self.original_to_base_halvings)
    end
  end
  
  ##############################################################
  # This will be slow, so it should be run in the background
  ##############################################################
  def process_source_directory(source_directory_name)
    # copy all jpegs into that directory
    debug("process_source_directory begin cp #{Time.now}")
    self.status = STATUS_RUNNING
    self.status_message = "copying files from source directory"
    self.save!
    cp(Dir.glob(File.join(source_directory_name, "*.jpg")), "#{self.path}")
    debug("process_source_directory end   cp #{Time.now}")
    debug("process_source_directory begin chmod #{Time.now}")
    original_files = Dir.glob(File.join(self.path, "*.jpg"))
    original_files.each { |f| File.chmod(0777, f) }
    self.status = STATUS_COMPLETE
    self.save!
    debug("process_source_directory end   chmod #{Time.now}")
  end

  # revision to earlier algorithm -- rotate full-sized images to be shrunk much later
  def process_orientation   
    self.step = STEP_ORIENTATION_PROCESS
    self.status = STATUS_RUNNING
    self.rotate_pid = Process.pid
    self.status_message = "rotating files"
    self.save!
    for image in self.titled_images
      if(!image.rotate_completed)
        debug("rotating image #{image.original_file true}")
        rotate(image, self.orientation, 0)
        image.rotate_completed = true
        image.save!
      end #if
    end #for
    self.status = STATUS_COMPLETE
    self.save!
  end

  def process_size   
    self.step = STEP_SIZE_PROCESS
    self.status = STATUS_RUNNING
    self.shrink_pid = Process.pid
    self.status_message = "resizing files"
    self.save!
    for image in self.titled_images
      debug("process_size: image #{image.id} 1.upto(#{self.original_to_base_halvings-1})")
      1.upto(self.original_to_base_halvings) do |i|
        debug("process_size shrinking image #{image.id} to #{i}")
        shrink(image, i)
      end
      image.shrink_completed = true
      image.save!
    end #for
    self.status = STATUS_COMPLETE
    self.save!
  end

  def process_crop
    debug("DEBUG number_location_process thinks set is READY, step=#{self.step}, status=#{self.status}, status_message=#{self.status_message}")
    self.step = STEP_NUMBER_LOCATION_PROCESS
    self.status = STATUS_RUNNING
    self.crop_pid = Process.pid
    self.status_message = "cropping files"
    self.save!
    for image in self.titled_images
      debug("process_crop cropping image #{image.id}")
      crop_sextodecimo(image, self.crop_band_start, self.crop_band_height)
      image.crop_completed = true
      image.save!
    end #for
    self.step = STEP_PROCESSING_COMPLETE
    self.status = STATUS_COMPLETE
    self.save!   
  end
  
  def debug(message) 
    logger.debug("  DEBUG: #{message}")
  end
end
