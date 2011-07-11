desc "Process source image directory"
task :process_image_dir => :environment do
  debug('processing source dir rake task begins')
  puts 'process_image_dir begins'
  
	@image_set = ImageSet.find(ENV['IMAGE_SET_ID'])
	source_directory_name = ENV['SOURCE_DIRECTORY_NAME']
	@image_set.process_source_directory(source_directory_name)
  
  puts 'process_image_dir ends'
  debug('processing source dir rake task ends')
end


task :process_orientation => :environment do
  puts "process orientation begins"
  debug('process orientation rake task begins')
  wait_on_prior_jobs(ImageSet::STEP_ORIENTATION_PROCESS, ImageSet::STEP_DIRECTORY_PROCESS)
  @image_set.process_orientation
  debug('process orientation rake task ends')
  puts "process orientation ends"
end

task :process_size => :environment do
  puts "process size begins"
  debug('process size rake task begins')
  wait_on_prior_jobs(ImageSet::STEP_SIZE_PROCESS, ImageSet::STEP_ORIENTATION_PROCESS)
  @image_set.process_size
  
  debug('process size rake task ends')
  puts "process size ends"
end

task :process_crop => :environment do
  puts "process crop begins"
  debug('process crop rake task begins')
  wait_on_prior_jobs(ImageSet::STEP_NUMBER_LOCATION_PROCESS, ImageSet::STEP_SIZE_PROCESS)
  @image_set.process_crop
  debug('process crop rake task ends')
  puts "process crop ends"
end

def wait_on_prior_jobs(this_step, prereq)
  @image_set = ImageSet.find(ENV['IMAGE_SET_ID'])
  tries = 0
  until current_step?(this_step) || prereq_is_done?(prereq) do
    tries += 1
    msg = "#{this_step}: image set is not ready (#{@image_set.step}:#{@image_set.status}); sleep ##{tries}"
    puts msg
    debug msg
    sleep(1)
    # reload to see if the status changed
    @image_set = ImageSet.find(ENV['IMAGE_SET_ID'])
    if tries > 3600 
      puts "waited an hour; bailing out!"
      break
    end       
  end
  msg = "#{this_step}: image set is READY (#{@image_set.step}:#{@image_set.status})"
  debug msg
  debug("ready to process image set #{@image_set}") 
end

def current_step? (this_step)
  @image_set.status == ImageSet::STATUS_RUNNING && @image_set.step == this_step
end

def prereq_is_done? (prereq)
  (@image_set.step == prereq && @image_set.status == ImageSet::STATUS_COMPLETE)
end

def debug(msg)
  RAILS_DEFAULT_LOGGER.debug("RAKE DEBUG #{msg}")
  RAILS_DEFAULT_LOGGER.flush
end