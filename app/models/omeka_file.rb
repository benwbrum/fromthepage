class OmekaFile < ActiveRecord::Base
  attr_accessible :fullsize_url, :mime_type, :omeka_id, :omeka_order, :original_filename, :thumbnail_url
  belongs_to :page, optional: true
  belongs_to :omeka_item, optional: true
end
