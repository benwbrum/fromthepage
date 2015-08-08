require 'image_helper'

namespace :fromthepage do

  desc "Resize image file or directories of image files"
  task :compress_images, [:pathname] => :environment  do  |t,args|
    pathname = args.pathname
    p "compressing #{pathname}"
    
    if Dir.exist? pathname
      ImageHelper.compress_files_in_dir(pathname)
    else
      # this is a single file
      ImageHelper.compress_file(pathname)
    end
  end



end