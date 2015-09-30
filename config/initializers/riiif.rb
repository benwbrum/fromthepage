require 'iiif/from_the_page_file_resolver'
#Riiif::Image.file_resolver.base_path = '/home/benwbrum/dev/products/fromthepage/fromthepage/public/images/working/71'#'/opt/repository/images/'

Riiif::Image.file_resolver = Riiif::FromThePageFileResolver.new

