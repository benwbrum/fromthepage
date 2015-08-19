class ScManifest < ActiveRecord::Base
  belongs_to :work
  belongs_to :sc_collection
  has_many :sc_canvases
end
