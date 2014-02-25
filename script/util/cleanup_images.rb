
require 'RMagick'
require 'lib/image_helper.rb'

#cut and paste from elsewhere
def rotate_file(file, orientation) 
  smaller = Magick::ImageList.new(file)
  smaller.rotate!(orientation)
  smaller.write(file)
  smaller = nil
  GC.start
end
def shrink_file(input_file, output_file, factor) 
  orig = Magick::ImageList.new(input_file)
  fraction = 1.to_f / (2.to_f ** factor)
  smaller = orig.resize(fraction)
  smaller.write(output_file)
  smaller = nil
  orig = nil
  GC.start
end
def shrunk_file(filename, factor = 2)
  if 0 == factor
    filename
  else
    filename.sub(/.jpg/, "_#{factor}.jpg")
  end
end


[1,6,8,10].each do |image_set_id|
  p "processing image set #{image_set_id}"
  image_set = ImageSet.find(image_set_id)
  p image_set.path
  # we have no titled images to work with
  # iterate over all the base image files in the directory
  files = Dir.glob(File.join(image_set.path, "[Ii][Mm][Gg]*[0-9][0-9][0-9][0-9].jpg"))
  files.each do |file|
    # make this idempotent
    unless File.exists?(shrunk_file(file,1))
      # rotate the base image
      p file
      begin 
        orientation = image_set.orientation
        rotate_file(file, orientation)
        
        # shrink it by 1
        
        shrink_file(file, shrunk_file(file, 1), 1)
      rescue ImageMagickError
        # redo file
        p "rescue block for #{file}"
        if File.exists? shrunk_file(file,1)
          p "removing shrunk file"
          File.unlink shrunk_file(file,1)
        end
        # copy it over from the orig directory
        orig_fn = File.join(image_set.path, 
                            "orig", 
                            File.basename(file))
        p "copying original file"
        p `cp #{orig_fn} #{image_set.path}`
      end
    end
  end  
end
