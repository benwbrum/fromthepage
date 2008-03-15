class Interaction < ActiveRecord::Base
  belongs_to :collection
  belongs_to :work
  belongs_to :page
  belongs_to :user
end
