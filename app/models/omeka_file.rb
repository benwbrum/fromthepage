class OmekaFile < ActiveRecord::Base
  belongs_to :page
  belongs_to :omeka_item
end
