require 'digest/sha1'

module SimpleCaptcha #:nodoc
  
  #--
  # The configuration constants have been set here.
  # * CAPTCHA_IMAGE_PATH
  # The simple captcha's images will be stored here,
  # the default is /public/images/captcha/.
  # * CAPTCHA_DATA_PATH
  # The simple captcha's session data wil be stored here, the default is /tmp/captcha/.
  # 
  # The path can be modified as needed.
  # The same modification is also required in the rake file.
  module Config #:nodoc
    IMAGE_PATH = "#{RAILS_ROOT}/public/images/"
    DATA_PATH = "#{RAILS_ROOT}/tmp/"
    CAPTCHA_IMAGE_PATH = "#{RAILS_ROOT}/public/images/simple_captcha/"
    CAPTCHA_DATA_PATH = "#{RAILS_ROOT}/tmp/simple_captcha/"
  end
  
  module ConfigTasks #:nodoc
    
    include Config
    
    def create_captcha_directories #:nodoc
      Dir.mkdir(IMAGE_PATH, 0777) unless File.exist?(IMAGE_PATH)
      Dir.mkdir(DATA_PATH, 0777) unless File.exist?(DATA_PATH)
      Dir.mkdir(CAPTCHA_DATA_PATH, 0777) unless File.exist?(CAPTCHA_DATA_PATH)
      Dir.mkdir(CAPTCHA_IMAGE_PATH, 0777) unless File.exist?(CAPTCHA_IMAGE_PATH)
    end
    
    def create_code #:nodoc
      captcha_hash_string = "simple captcha by sur http://expressica.com"
      Digest::SHA1.hexdigest(captcha_hash_string + session.session_id + captcha_hash_string)
    end
    
    def remove_simple_captcha_files #:nodoc
      begin
        ttl = 1.hours.ago
        Dir.foreach(CAPTCHA_IMAGE_PATH) do |file_name| 
          file = CAPTCHA_IMAGE_PATH + file_name
          if File.mtime(file) < ttl
            file_data = file_name.split(".").first
            File.delete(file) 
            data = PStore.new(CAPTCHA_DATA_PATH + "data")
            data.transaction{data.delete(file_data)}
          end
        end
      rescue
        return nil
      end
    end
    
    private :create_code
  end
end
