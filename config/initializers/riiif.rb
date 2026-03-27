require 'iiif/from_the_page_file_resolver'
# Riiif::Image.file_resolver.base_path = '/home/benwbrum/dev/products/fromthepage/fromthepage/public/images/working/71'#'/opt/repository/images/'

ActiveSupport::Reloader.to_prepare do
  Riiif::Image.file_resolver = Riiif::FromThePageFileResolver.new

  # Override the redirect action to use the app's route helpers instead of
  # the engine's `riiif` helper, which is not available when routes are added
  # via `iiif_for` rather than mounted as an engine.
  Riiif::ImagesController.class_eval do
    def redirect
      redirect_to info_path(params[:id])
    end
  end
end
