require 'image_helper'

namespace :fromthepage do

  desc "Resize image file"
  task :compress_image, [:filename] => :environment  do  |t,args|
    filename = args.filename
    p "compressing file #{filename}"
    ImageHelper.compress(filename)
  end

end