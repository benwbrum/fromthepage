class OmekaFile < ActiveRecord::Base
  attr_accessible :fullsize_url, :mime_type, :omeka_id, :omeka_order, :original_filename, :thumbnail_url
  belongs_to :page
  belongs_to :omeka_item
end
