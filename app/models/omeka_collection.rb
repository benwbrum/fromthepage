class OmekaCollection < ActiveRecord::Base
  attr_accessible :description, :omeka_id, :title
  belongs_to :omeka_site, optional: true
  belongs_to :collection, optional: true
end
