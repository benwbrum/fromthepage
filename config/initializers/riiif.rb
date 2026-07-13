require 'iiif/from_the_page_file_resolver'
# Riiif::Image.file_resolver.base_path = '/home/benwbrum/dev/products/fromthepage/fromthepage/public/images/working/71'#'/opt/repository/images/'

ActiveSupport::Reloader.to_prepare do
  Riiif::Image.file_resolver = Riiif::FromThePageFileResolver.new
end

module RiiifImagesControllerRedirectPatch
  def info
    response.headers['X-Robots-Tag'] = 'noindex'
    super
  end

  def redirect
    response.headers['X-Robots-Tag'] = 'noindex'
    redirect_to "/image-service/#{ERB::Util.url_encode(params[:id].to_s)}/info.json"
  end
end

ActiveSupport::Reloader.to_prepare do
  next if Riiif::ImagesController < RiiifImagesControllerRedirectPatch

  Riiif::ImagesController.prepend(RiiifImagesControllerRedirectPatch)
end
