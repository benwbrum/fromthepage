class TransformController < ApplicationController
  require 'fileutils'
  include FileUtils::Verbose
  include Magick
  include ImageHelper
  # TODO add before filters

  NEXT_STEP =
    {
      ImageSet::STEP_DIRECTORY_PROCESS => 'orientation_form',
      ImageSet::STEP_ORIENTATION_PROCESS => 'number_location_form',
      ImageSet::STEP_NUMBER_LOCATION_PROCESS => 'number_format_form'
    }

  def index
    if @image_set
      reprise
    else
      render :action => 'directory_form'
    end
  end

  def reprise
    debug('L 1')
    unless @image_set
      debug('L 2')
      redirect_to :action => 'directory_form'
      return
    end
    debug('L 3')
    debug("RAW IMAGE_SET STEP= #{@image_set.step}")

    next_step = NEXT_STEP[@image_set.step]

    # figure out the current step
    # if it's completed, redirect to the next step
    if @image_set.status = ImageSet::STATUS_COMPLETE
      debug('L 4')
      debug("REDIRECTING TO #{next_step}")
      redirect_to :action => next_step, :image_set_id => @image_set.id
      debug('L 5')

      return
    end
    debug('L 6')
    # if it's not, show an apologetic explanation
    render :text => @image_set.status + ' ' + @image_set.status_message
    debug('L 7')

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
      redirect_to :action => 'reprise', :image_set_id => config[:image_set_id]
    end
  end

  def orientation_form
    # pick a randomish file to use as a sample
    sample_image = @image_set.sample_image
    filename = sample_image.shrunk_file

    debug("begin orient #{Time.now}")
    # shrink the sample image even more
    orig = Magick::ImageList.new(filename)
    quarter = 1.to_f / 2.to_f
    base = orig.resize(quarter)
    @img_files = Hash.new

    debug(@image_set.inspect)
    dirname = @image_set.path
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
    @image_set.orientation = orientation
    @image_set.save!

    #rotate_sextodecimo(@image_set.sample_image, orientation)
    # MiddleMan.get_worker(session[:job_key]).begin_rotate_sextodecimo(orientation)

    @image_set.process_sample_orientation
    call_rake :process_orientation

    # TODO set orientation on image_set
    redirect_to :action => 'size_form', :image_set_id => config[:image_set_id]
  end

  def size_form

  end


  def size_process
    action = params['size']
    if 'just_right' == action
      call_rake :process_size
      redirect_to :action => 'number_location_form', :image_set_id => @image_set.id
      return
    end
    # otherwise shrink/enlarge the image and re-display the form
    if 'too_small' == action
      @image_set.original_to_base_halvings -= 1
    else
      @image_set.original_to_base_halvings += 1
    end
    @image_set.save!
    @image_set.resize_sample_image

    render :action => 'size_form'
  end

  def number_location_form
    @image = @image_set.sample_image
  end

  # TODO move the image dimensions onto the titled_image object
  def number_location_process
    # we really don't care about the x coordinate
    y = params['coordinate.y'].to_i
    debug y

    # TODO refactor to pull the image dimensions from the image_set object
    sample_image = @image_set.sample_image
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

    @image_set.crop_band_start = start_of_band
    @image_set.crop_band_height = band_height
    @image_set.save!

    # TODO refactor this to use the lib code
    crop_sextodecimo(sample_image, start_of_band, band_height)
    safe_update(sample_image, { :crop_completed => true })
    # apply the crop to the rest of the pages
    debug("Cropping other files...")
    call_rake :process_crop
#    MiddleMan.get_worker(session[:job_key]).begin_crop_sextodecimo(start_of_band, band_height)

    redirect_to :action => 'number_format_form', :image_set_id => config[:image_set_id]
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
      redirect_to :action => 'date_format_form', :image_set_id => config[:image_set_id]
    else
      redirect_to :action => 'numeric_format_start_form', :image_set_id => config[:image_set_id]
    end
  end

  def numeric_format_start_form

  end

  def numeric_format_start_process
    config[:numeric_start] = params[:numeric_start]
    redirect_to :action => 'partial_list_form', :image_set_id => config[:image_set_id]
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
    @image_set.title_format = date_format
    @image_set.save!
    redirect_to :action => 'date_format_start_form', :image_set_id => config[:image_set_id]
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
                :image_set_id => config[:image_set_id])
  end

  #############################################################################
  # Process meter
  #
  # Displays status of different processing steps.
  #############################################################################
  def process_meter
    @total_images = @image_set.titled_images.count
    @shrunk_images = @image_set.titled_images.count(:conditions => ['shrink_completed = ?', true])
    @rotated_images = @image_set.titled_images.count(:conditions => ['rotate_completed = ?', true])
    @cropped_images = @image_set.titled_images.count(:conditions => ['crop_completed = ?', true])
    @shrink_process_count = `ps -p #{@image_set.shrink_pid} h| wc -l`.chomp.to_i
    @rotate_process_count = `ps -p #{@image_set.rotate_pid} h| wc -l`.chomp.to_i
    @crop_process_count = `ps -p #{@image_set.crop_pid} h| wc -l`.chomp.to_i
  end

  def restart
    call_rake :process_orientation
    call_rake :process_size
    call_rake :process_crop

    redirect_to :action => 'process_meter', :image_set_id => @image_set.id
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


  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    options[:image_set_id] = @image_set.id
    args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
    rake_call = "#{RAKE} #{task} #{args.join(' ')}  --trace 2>&1 >> #{Rails.root}/log/rake.log &"
    debug("DEBUG: #{rake_call}")
    system rake_call
  end


  def process_source_directory(source_directory_name)
    # create a working directory
    debug("current directory is #{Dir.getwd}")
    @image_set = ImageSet.new
    @image_set.owner = current_user
    @image_set.save!

    # do the inline work
    @image_set.directory_setup(source_directory_name)

    # do the background work
    call_rake :process_image_dir, :source_directory_name => source_directory_name

    # looks lame
    config[:image_set_id] = @image_set.id

  end

  def auto_title
    # set up the original
    date_string = config[:date_start]
    current_date = Date.parse(date_string)
    debug(current_date.to_s)
    date_format = @image_set.title_format
    # walk through each image
    for image in @image_set.titled_images
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

  def configure
    if(nil == session[:collation_config])
      session[:collation_config] = {}
    end
    session[:collation_config]
  end

  def debug(message)
    logger.debug("  DEBUG: #{message}")
  end

end
