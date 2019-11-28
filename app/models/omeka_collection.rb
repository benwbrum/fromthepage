class OmekaCollection < ApplicationRecord
  belongs_to :omeka_site, optional: true
  belongs_to :collection, optional: true
end
