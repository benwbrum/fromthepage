class Notification < ActiveRecord::Base
  belongs_to :user

  attr_accessible :add_as_owner, :add_as_collaborator, :work_added, :page_edited, :note_added, :owner_stats 
end
