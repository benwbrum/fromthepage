module Riiif
  class FromThePageFileResolver
    attr_accessor :root, :base_path, :input_types

    def initialize
      @root = ::File.expand_path(::File.join(::File.dirname(__FILE__), '../..'))
      @base_path = '/home/benwbrum/dev/products/fromthepage/fromthepage/public/images/working/71'#'/opt/repository/images/')
      @input_types = %W{png jpg}
    end

    def find(id)
      raise ArgumentError, "Invalid characters in id `#{id}`" unless /^\d+$/.match(id)

      page = Page.find(id.to_i) || raise(ImageNotFoundError, id)
      
      path = path(page.base_image)
      
      Riiif::File.new(path)
    end

    def path(filename)
      # sometimes FromThePage stores absolute paths for file uploads, which is consistent within the same server but don't copy easily
      relative_path = filename.sub(/.*public/, "")
      File::Stat::File.join(Rails.root, 'public', relative_path)  # specify module for file to avoid conflict with Riiif::File
    end
    
  end
end
