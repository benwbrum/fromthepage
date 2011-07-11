class CollationController < ApplicationController
  include FileUtils::Verbose

  before_filter :authorized?

  def authorized?
    if logged_in? && current_user.owner
      logger.debug("testing params")
      id = if params[:image_set_id] == nil || params[:image_set_id] == ""
        params[:left_set_id]
      else 
        params[:image_set_id]
      end
      set = ImageSet.find(id)
      logger.debug("found #{set.inspect}")
      return set.owner == current_user
    end
  end
    
  def select_target
    @right_set = @image_set
    @left_sets = current_user.image_sets
    @left_sets.delete(@right_set)
  end

  def select_target_process
    redirect_to(:action=>'list', 
                :right_set_id => params[:right_set_id],
                :left_set_id => params[:left_set_id])
  end

  def list
    @right_set = ImageSet.find(params[:right_set_id])
    @left_set = ImageSet.find(params[:left_set_id])
  end

  def swap
    redirect_to(:action => 'list',
                :left_set_id => params[:right_set_id],
                :right_set_id => params[:left_set_id])
  end

  def insert
    image = TitledImage.new
    image.title = 'Blank'
    image.original_file = 'blank'
    insert_set = ImageSet.find(params[:insert_set_id])
    index = params[:index].to_i 
    index += 1
    if(params[:where]=='after')
      index += 1
    end
    # this silently saves the new image
    insert_set.titled_images << image
#    insert_set.save!
#    logger.debug("After    save #{image.position}")
#    logger.debug("Before insert #{image.position}")
    # this updates all records in the DB but does not
    # reload them in memory -- at this point objects
    # in memory are stale
    image.insert_at(index)
#    logger.debug("After  insert #{image.position}")
#    image.save!
#    insert_set.save!
#    logger.debug("After    save #{image.position}")
    # now redirect
    redirect_to(:action => 'list',
                :left_set_id => params[:left_set_id],
                :right_set_id => params[:right_set_id])

  end

  

  def merge
    # load up the sets
    left_set = ImageSet.find(params[:left_set_id])
    right_set = ImageSet.find(params[:right_set_id])
    # create a new image set
    new_set = ImageSet.new
    new_set.owner = current_user
    # copy the relevant image set data
    new_set.title_format = left_set.title_format
    new_set.original_to_base_halvings = left_set.original_to_base_halvings
    new_set.step = ImageSet::STEP_PROCESSING_COMPLETE
    new_set.status = ImageSet::STATUS_COMPLETE
    new_set.save!
    new_set.create_new_directory
    # now start copying images over
    # the associations will not be saved until the
    # parent is saved.  who knows what will happen to
    # the position attributes?
    left_size = left_set.titled_images.size
    right_size = right_set.titled_images.size
    min_size = left_size > right_size ? right_size : left_size
    max_size = left_size < right_size ? right_size : left_size
    
    0.upto(max_size-1) do |i|
      # append the left element here
      if i < left_size
        new_set.titled_images << left_set.titled_images[i]
      end
      # append the right element
      if i < right_size
        new_set.titled_images << right_set.titled_images[i]
      end
    end
    # this has no effect on acts as list unless I do it manually
    1.upto(new_set.titled_images.size) do |i|
      new_set.titled_images[i-1].position=i
    end
    # actually copy the files over
    mv(Dir.glob(File.join(left_set.path, "*.jpg")), new_set.path, :force => true)
    mv(Dir.glob(File.join(right_set.path, "*.jpg")), new_set.path, :force => true)
    new_set.save!
    redirect_to :controller => 'title', :action => 'list', :image_set_id => new_set.id
  end


end
