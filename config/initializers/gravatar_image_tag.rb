# Be sure to restart your server when you modify this file.

GravatarImageTag.configure do |config|
  # Set this to use your own default gravatar image rather then serving up Gravatar's default image [ 'http://example.com/images/default_gravitar.jpg', :identicon, :monsterid, :wavatar, 404 ]
  config.default_image = 'blank'

  # Set this if you require a specific image file format ['gif', 'jpg' or 'png'].  Gravatar's default is png
  config.filetype = nil

  # The height and width attributes of the generated img will be set to avoid page jitter as the gravatars load.  Set to false to leave these attributes off
  config.include_size_attributes = true

  # Set this if you change the rating of the images that will be returned ['G', 'PG', 'R', 'X']. Gravatar's default is G
  config.rating = nil

  # Set this to globally set the size of the gravatar image returned (1..512). Gravatar's default is 80
  config.size = 80

  # Set this to true if you require secure images on your pages
  config.secure = true
end