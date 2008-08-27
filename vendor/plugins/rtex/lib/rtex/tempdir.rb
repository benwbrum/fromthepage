require 'fileutils'

module RTeX
  
  class Tempdir #:nodoc:
        
    def self.open(parent_path=RTeX::Document.options[:tempdir])
      tempdir = new(parent_path)
      FileUtils.mkdir_p tempdir.path
      result = Dir.chdir(tempdir.path) do
        yield tempdir
      end
      # We don't remove the temporary directory when exceptions occur,
      # so that the source of the exception can be dubbed (logfile kept)
      tempdir.remove!
      result
    end
    
    def initialize(parent_path, basename='rtex')
      @parent_path = parent_path
      @basename = basename
      @removed = false
    end
    
    def path
      @path ||= File.expand_path(File.join(@parent_path, 'rtex', "#{@basename}-#{uuid}"))
    end
    
    def remove!
      return false if @removed
      FileUtils.rm_rf path
      @removed = true
    end
    
    #######
    private
    #######
    
    # Try using uuidgen, but if that doesn't work drop down to
    # a poor-man's UUID; timestamp, thread & object hashes
    # Note: I don't want to add any dependencies (so no UUID library)
    def uuid
      if (result = `uuidgen`.strip rescue nil).empty?
        "#{Time.now.to_i}-#{Thread.current.hash}-#{hash}"
      else
        result
      end
    end
    
  end
  
end