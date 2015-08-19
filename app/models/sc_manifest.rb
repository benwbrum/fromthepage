class ScManifest < ActiveRecord::Base
  belongs_to :work
  belongs_to :sc_collection
end
