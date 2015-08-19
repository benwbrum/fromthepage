class ScCanvas < ActiveRecord::Base
  belongs_to :sc_manifest
  belongs_to :page
  
  
  def thumbnail_url
    "#{sc_service_id}/full/100,/0/default.jpg"
  end
  def facsimile_url
    "#{sc_service_id}/full/full/0/default.jpg"
  end
end
