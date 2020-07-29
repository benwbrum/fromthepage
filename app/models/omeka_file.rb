class OmekaFile < ApplicationRecord
  belongs_to :page, optional: true
  belongs_to :omeka_item, optional: true
end
