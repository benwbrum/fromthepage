class Notification < ApplicationRecord
  belongs_to :user, optional: true

  attr_accessible :add_as_owner, :add_as_collaborator, :work_added,  :note_added, :owner_stats, :user_activity
end
