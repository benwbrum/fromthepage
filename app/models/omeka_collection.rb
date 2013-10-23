class OmekaCollection < ActiveRecord::Base
  attr_accessible :description, :omeka_id, :title
  belongs_to :omeka_site
  belongs_to :collection
end
