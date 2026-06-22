module Riiif
  class FromThePageFileResolver
    attr_accessor :root, :base_path, :input_types

    def initialize
      @root = ::File.expand_path(::File.join(::File.dirname(__FILE__), '../..'))
      @base_path = '/home/benwbrum/dev/products/fromthepage/fromthepage/public/images/working/71'# '/opt/repository/images/')
      @input_types = %W[png jpg]
    end

    def find(id)
      raise ArgumentError, "Invalid characters in id `#{id}`" unless /^\d+$/.match(id)

      page = Page.find(id.to_i) || raise(ImageNotFoundError, id)

      if page.image.attached?
        file_path = path_for_active_storage_image(page.image)
        return Riiif::File.new(file_path)
      end

      raise ImageNotFoundError, id if page.base_image.blank?

      Riiif::File.new(path(page.base_image))
    end

    def path(filename)
      # sometimes FromThePage stores absolute paths for file uploads, which is consistent within the same server but don't copy easily
      relative_path = filename.sub(/.*public/, '')
      "#{Rails.root}/public/#{relative_path}"
    end

    private

    def path_for_active_storage_image(image)
      blob = image.blob
      service = blob.service

      # Use path_for if the service exposes it (disk service does; S3 does not).
      if service.respond_to?(:path_for)
        service.path_for(blob.key)
      else
        # For non-disk services (e.g., S3), download to a local cache directory
        # so Riiif can process the image with ImageMagick.
        ext = blob.filename.extension_with_delimiter.presence || '.bin'
        cache_dir = Rails.root.join('tmp', 'riiif_cache')
        FileUtils.mkdir_p(cache_dir)
        cached_path = cache_dir.join("#{blob.key}#{ext}").to_s

        unless ::File.exist?(cached_path)
          blob.open do |tmp_file|
            FileUtils.cp(tmp_file.path, cached_path)
          end
        end

        cached_path
      end
    end
  end
end
