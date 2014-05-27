class TitleController < ApplicationController
  include ImageHelper

  protect_from_forgery :except => [:set_titled_image_title]
  before_filter :authorized?,
    :only =>
      [:list]

  def authorized?
    if user_signed_in? && current_user.owner
      return @image_set.owner == current_user
    end
  end

  def list
    unless @image_set.status == ImageSet::STATUS_COMPLETE
      redirect_to :controller => 'transform', :action => 'process_meter', :image_set_id => @image_set.id
    end
    @titled_images = @image_set.titled_images
    conditions = "image_set_id = #{@image_set.id}"
#    @image_pages, @titled_images = paginate(:titled_image,
#                                            {:per_page => 10,
#                                             :conditions => conditions,
#                                             :order => 'position' })
  end

  def delete_image
    @image_set.titled_images.delete(@titled_image)
    @image_set.save!
    @titled_image.destroy
    redirect_to :action => 'list', :image_set_id => @image_set.id
  end

  def increment_by_one
    renumber_images(1)
  end

  def increment_by_two
    renumber_images(2)
  end

  def increment_by_ten
    renumber_images(10)
  end

  def increment_by_365
    renumber_images(365)
  end

  def decrement_by_one
    renumber_images(-1)
  end

  def decrement_by_two
    renumber_images(-2)
  end

  def decrement_by_ten
    renumber_images(-10)
  end

  def decrement_by_365
    renumber_images(-365)
  end

  def update
    image = TitledImage.find(params[:id])
    image.update_attributes(params[:image])
    flash[:notice] = "Title updated successfully."
    redirect_to :back
  end

private

  def renumber_images(change_by)
    start_position = @titled_image.position
    date_format = @image_set.title_format
    images = @image_set.titled_images
    for image in images
      if image.position >= start_position
        image = TitledImage.find(image.id)
        # consider doing this within a transaction
        logger.debug("DEBUG: image to be changed is #{image.inspect}")
        date = Date.parse(image.title_seed)
        date += change_by
#        image.update_attributes({:title_seed => date.to_s,
#                                  :title => date.strftime(date_format)})
#        TitledImage.transaction(image) do
#          image.title_seed = date.to_s
#          image.title = date.strftime(date_format)
#          image.save!
#        end

        safe_update(image,
                    { :title_seed => date.to_s,
                      :title => date.strftime(date_format)})
      end
    end
    redirect_to :action => 'list', :image_set_id => @image_set.id, :page => params[:page]
  end
end
