namespace :fromthepage do
  desc 'clean up image files from deleted works'
  task image_cleanup: :environment do
    path = Rails.public_path.join('images', 'uploaded')
    Dir.chdir(path) do
      # look at folders within the image path for all works
      # if there is no work with the id of the folder name, delete images and folder
      Dir.glob('**').each do |f|
        next if Work.find_by(id: f.to_i)

        new_dir_name = File.join(path, f)
        next unless Dir.exist?(new_dir_name)

        puts new_dir_name
        Dir.glob(File.join(new_dir_name, '*')) { |file| File.delete(file) }
        Dir.rmdir(new_dir_name)
      end
    end
  end
end
