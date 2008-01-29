class TransformController < ApplicationController
  require 'fileutils'
  require 'RMagick'
  include FileUtils::Verbose
  include Magick
  include ImageHelper
# TODO add before filters

  def index
    render :action => 'directory_form'
  end

  def splash_page
  
  end
  
  def test_backgroundrb
    # don't call new_worker each time -- rather call get_worker and a method off that.
    session[:job_key] = MiddleMan.new_worker(:class => :image_transformer_worker,
                                             :args => { :directory => config[:working_directory],
                                               :files => config[:original_files]} )
    MiddleMan.get_worker(session[:job_key]).begin_shrink_to_sextodecimo
    MiddleMan.get_worker(session[:job_key]).begin_rotate_sextodecimo
    MiddleMan.get_worker(session[:job_key]).begin_crop_sextodecimo
    render :action => 'directory_form'
  end


  #############################################################################
  # Main Flow
  # 
  # Gathers information about images for the config object and  launches image 
  # manipulation
  #############################################################################

  def directory_form
    debug(test_helper())
  end

  def directory_process
    source_dir = params[:directory]

    # check that input appeared
    if(source_dir == nil || "" == source_dir)
      flash.now['error'] = "You must enter a directory"
      render :action => 'directory_form'
    elsif(!File.directory?(source_dir))      # check for a valid directory
      flash.now['error'] = "The directory (#{source_dir}) entered is not a valid directory"
      render :action => 'directory_form'
    elsif(!File.executable?(source_dir))
      flash.now['error'] = 
        "The application does not have execute permission on the directory #{source_dir}"
      render :action => 'directory_form'
    elsif(!File.readable?(source_dir))
      flash.now['error'] = 
        "The application does not have read permission on the directory #{source_dir}"
      render :action => 'directory_form'
    elsif(Dir.entries(source_dir).length < 3)
      flash.now['error'] = 
        "There are no files in the directory #{source_dir}"
      render :action => 'directory_form'
    else
      config[:source_directory] = source_dir
      process_source_directory(source_dir)
      redirect_to :action => 'orientation_form'
    end
  end
  
  def orientation_form
    sample = config[:sample_image]
    filename = sample.shrunk_file
    
    debug("begin orient #{Time.now}")
    # shrink the sample image even more
    orig = Magick::ImageList.new(filename)
    quarter = 1.to_f / 2.to_f
    base = orig.resize(quarter)
    @img_files = Hash.new
    
    debug(config[:image_set].inspect)
    dirname = config[:image_set].path
    # loop through each orientation and produce samples
    [0, 90, 180, 270].each do |angle|
      image = base.rotate(angle)
      filename = File.join(dirname, "#{angle}.jpg")
      image.write(filename)
      @img_files["#{angle}"] = filename
    end
    debug("end   orient #{Time.now}")
  end
  
  def orientation_process
    # get the orientation
    orientation = params[:orientation].to_f
    image_set = config[:image_set]
    image_set.orientation = orientation
    image_set.save!

    rotate_sextodecimo(config[:sample_image], orientation)
    MiddleMan.get_worker(session[:job_key]).begin_rotate_sextodecimo(orientation)
    # TODO set orientation on image_set
    redirect_to :action => 'number_location_form'
  end
  
  def number_location_form
    @image = config[:sample_image]
  end

  # TODO move the image dimensions onto the titled_image object
  def number_location_process
    # we really don't care about the x coordinate
    y = params['coordinate.y'].to_i
    debug y

    # TODO refactor to pull the image dimensions from the image_set object
    sample_image = config[:sample_image]
    sample_file = sample_image.shrunk_file
    sample = Magick::ImageList.new(sample_file)
    height = sample.rows
    band_height = 80

    if (y < (band_height / 2))
      # the point is closer to the top than expected
      center_of_band = band_height / 2
    elsif (y > (height - (band_height/2)))
      center_of_band = (height - (band_height/2))
    else
      center_of_band = y
    end
    start_of_band = center_of_band - (band_height/2)

    # TODO refactor this to use the lib code
    crop_sextodecimo(sample_image, start_of_band, band_height)
#    sample_image.crop_completed = true
#    sample_image.save!    
    safe_update(sample_image, { :crop_completed => true })
    # apply the crop to the rest of the pages
    debug("Cropping other files...")
    MiddleMan.get_worker(session[:job_key]).begin_crop_sextodecimo(start_of_band, band_height)
    
    redirect_to :action => 'number_format_form'
  end
  

  #############################################################################
  # Numeric Format Branch
  # 
  # Gathers numeric-specific information for the config object
  #############################################################################
  def number_format_form
    # TODO: fix title controller
    @image = config[:sample_image]
  end
  
  def number_format_process
    config[:number_format] = params[:format]
    config[:interval_sequential] = (params[:interval] == 'Sequential')
    if('Date' == config[:number_format])
      redirect_to :action => 'date_format_form'
    else
      redirect_to :action => 'numeric_format_start_form'
    end
  end

  def numeric_format_start_form
    
  end

  def numeric_format_start_process
    config[:numeric_start] = params[:numeric_start]
    redirect_to :action => 'partial_list_form'
  end

  #############################################################################
  # Date Format Branch
  # 
  # Gathers date-specific information for the config object
  #############################################################################
  def date_format_form
    @image = config[:sample_image]
  end

  def date_format_process
    # take the date input
    date_format  = params[:date_format_string]
    config[:date_format_string] = date_format

    # find out if it's valid
    test_date = Time.now
    if(test_date.strftime(date_format) == date_format)
      # re-render with an error message if it's not
      flash.now['error'] = "Your date format was invalid"
      render :action => 'date_format_form'
    end
    config[:image_set].title_format = date_format
    config[:image_set].save!
    redirect_to :action => 'date_format_start_form'
  end

  def date_format_ajax_test
    date_format = params[:date_format_string]
    test_date = Time.now
    
    if request.xhr? 
      render(:text => test_date.strftime(date_format), :layout => false)
    else  
      render :action => 'date_format_form'
    end
  end

  def date_format_start_form
  
  end

  def date_format_start_process
    config[:date_start] = params[:date_start]
    # date all the titled images
    auto_title
    # redirect 
    redirect_to(:controller => 'title', 
                :action => 'list', 
                :image_set_id => config[:image_set].id)
  end


  #############################################################################
  # List Flow
  # 
  # Manipulates partial lists
  #############################################################################
  def partial_list_form
    @current = config
    @number_images = []
    config[:original_files].each do |original|
      @number_images << file_to_url(cropize(original))
    end
  end

private
  def process_source_directory(source_directory_name)
    # create a working directory
    debug("current directory is #{Dir.getwd}")
    new_set = ImageSet.new
    new_set.owner = current_user
    new_set.save!

    # looks lame
    new_dir_name = File.join(File.join(Dir.getwd, 
                                       File.join("images",
                                                 "working")), 
                             new_set.id.to_s) 
   
    if(!Dir.mkdir(new_dir_name))
      debug("could not create directory #{new_dir_name}")
    end
    if(!File.chmod(0777, new_dir_name))
      debug("could not chmod directory #{new_dir_name}")
    end
    new_set.path = new_dir_name
        
    # copy all jpegs into that directory
    debug("begin cp #{Time.now}")
    cp(Dir.glob(File.join(source_directory_name, "*.jpg")), "#{new_dir_name}")
    debug("end   cp #{Time.now}")
    debug("begin dir #{Time.now}")
    original_files = Dir.glob(File.join(new_dir_name, "*.jpg"))
    original_files.each { |f| File.chmod(0777, f) }
    debug("end   dir #{Time.now}")

    original_files.sort!
    original_files.each do |image_filename|
      image = TitledImage.new
      image.original_file = image_filename
      new_set.titled_images << image
    end
    new_set.save!
    
    config[:image_set] = new_set
    # TODO move most of this config stuff to the image set object
    

    # pick a randomish file to use as a sample
    sample_image = new_set.titled_images[(new_set.titled_images.length / 3)]
    config[:sample_image] = sample_image
      
    # set default image data
    orig = Magick::ImageList.new(sample_image.original_file)
    new_set.original_width = orig.columns
    new_set.original_height = orig.rows
    
    # set shrinkage -- eventually will be its own workflow
    new_set.original_to_base_halvings = 2
    new_set.save!
    

    debug("begin shrink #{Time.now}")
    # shrink the sample file to 1:4
    shrink_to_sextodecimo(sample_image)
    debug("end   shrink #{Time.now}")

    # spawn a 1:4 shrink of the remaining files
    session[:job_key] = MiddleMan.new_worker(:class => :image_transformer_worker,
                                             :args => { :image_set_id => new_set.id } )

    MiddleMan.get_worker(session[:job_key]).begin_shrink_to_sextodecimo

  end

  def auto_title
    # set up the original
    date_string = config[:date_start]
    current_date = Date.parse(date_string)
    debug(current_date.to_s)
    iset = config[:image_set]
    date_format = iset.title_format
    # walk through each image
    for image in iset.titled_images
      image = TitledImage.find(image.id)
      safe_update(image, 
                  { :title_seed => current_date.to_s, 
                    :title => current_date.strftime(date_format)})  
      if(config[:interval_sequential])
        current_date += 1 
      else
        current_date += 2
      end
    end
  end

  def config
    if(nil == session[:collation_config]) 
      session[:collation_config] = {}
    end
    session[:collation_config]
  end

  def debug(message) 
    logger.debug("  DEBUG: #{message}")
  end

end
