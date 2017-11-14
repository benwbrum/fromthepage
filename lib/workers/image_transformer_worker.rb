=begin
require 'drb'
require 'rmagick'
require File.dirname(__FILE__) + '/../image_helper.rb'


class ImageTransformerWorker < BackgrounDRb::Rails
  include DRbUndumped
  include Magick
  include ImageHelper

  # This gets called by the MiddleMan when you call
  # new_worker in your app. args is set to whatever
  # you stated in the new_worker call. Setup your
  # vars here and call start_working.
  def do_work(args)
    @logger.debug("Rails.env=#{Rails.env}")
    @args = args

    @image_set = ImageSet.find(@args[:image_set_id].to_i)

    @logger.debug("initialize called with #{args.inspect}")


    @shrink_thread = nil
    @rotate_thread = nil
  end

  # TODO add a task for the copy


  def begin_shrink_to_sextodecimo
    @logger.debug("begin_shrink_to_sextodecimo")

    @shrink_thread = Thread.new do
      for image in @image_set.titled_images
        image = TitledImage.find(image.id)
        @logger.debug("shrink_to_sextodecimo testing #{image.id}")
        if(!image.shrink_completed)
          shrink_to_sextodecimo(image)
        end #if
      end #for
    end #thread
  end

  def begin_rotate_sextodecimo(orientation)
    @rotate_thread = Thread.new do
      for image in @image_set.titled_images
        # refresh the image from the db
        image = TitledImage.find(image.id)
        @logger.debug("rotate_sextodecimo testing #{image.id}")
        if(!image.shrink_completed)
          # wait on the shrink thread to finish
          @logger.debug("rotate_sextodecimo waiting for shrink at #{image.id}")
          @shrink_thread.join
        end
        # now rotate
        if(!image.rotate_completed)
          rotate_sextodecimo(image, orientation)
        end #if
      end #for
    end #do
  end

  # TODO redo this
  def begin_crop_sextodecimo(start_of_band, band_height)
    @logger.debug("Crop: worker begins cropping")
    # do stuff with the xy values
    @crop_thread = Thread.new do
      for image in @image_set.titled_images
        # refresh the image from the db
        image = TitledImage.find(image.id)
        @logger.debug("crop_sextodecimo testing #{image.id}")
        if(!image.rotate_completed)
          # wait on the shrink thread to finish
          @logger.debug("crop_sextodecimo waiting for rotate at #{image.id}")
          @rotate_thread.join
        end
        # now crop
        if(!image.crop_completed)
          crop_sextodecimo(image, start_of_band, band_height)
        end #if
      end #for

      @logger.debug("Crop: worker begins post-processing")
      image_set = ImageSet.find(@image_set.id)
      @logger.debug("Crop: image_set #{@image_set.inspect}")
      for image in image_set.titled_images
        @logger.debug("Crop: image #{image.id}")
        @logger.debug("Crop: image #{image.id} rotate #{image_set.orientation}")
        rotate(image, image_set.orientation, 0)
        @logger.debug("Crop: image #{image.id} 1.upto(#{image_set.original_to_base_halvings-1})")
        1.upto(image_set.original_to_base_halvings - 1) do |i|
          @logger.debug("Crop: shrinking image #{image.id} to #{i}")
          shrink(image, i)
        end
      end

    end #do
  end


end
=end