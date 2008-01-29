require 'pstore'
desc "Remove unuseful captcha images and sessions data"
task :remove_simple_captcha_files do
  image_path = "#{RAILS_ROOT}/public/images/simple_captcha/"
  data_path = "#{RAILS_ROOT}/tmp/simple_captcha/"
  ttl = 1.hours.ago
  Dir.foreach(image_path) do |file_name| 
	file = image_path + file_name
	if File.mtime(file) < ttl
	   file_data = file_name.split(".").first
	   File.delete(file) 
	   begin
		data = PStore.new(data_path + "data")
		data.transaction{data.delete(file_data)}
	   rescue
		puts "error while running rake task"
	   end
	end
  end if File.exist?(image_path) and File.exist?(data_path)
  puts "Captcha files removed!"
end