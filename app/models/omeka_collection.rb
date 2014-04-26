class OmekaCollection < ActiveRecord::Base
  belongs_to :omeka_site
  belongs_to :collection
end
