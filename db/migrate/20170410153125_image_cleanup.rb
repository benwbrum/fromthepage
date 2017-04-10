class ImageCleanup < ActiveRecord::Migration
  #clean up of file image storage for works that have been deleted
  def change
    path = File.join(Rails.root, "public", "images", "uploaded")
    Dir.chdir(path) do
      #look at folders within the image path for all works
      #if there is no work with the id of the folder name, delete images and folder
      Dir.glob("**").sort.each do |f|
        unless Work.find_by(id: f.to_i)
          new_dir_name = File.join(path, f)
          if Dir.exist?(new_dir_name)
            puts new_dir_name
            Dir.glob(File.join(new_dir_name, "*")) {|file| File.delete(file)}
            Dir.rmdir(new_dir_name)
          end
        end
      end
    end
  end
end
