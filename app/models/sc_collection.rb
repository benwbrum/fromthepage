class ScCollection < ActiveRecord::Base
  belongs_to :collection
  has_many :sc_manifests
end
