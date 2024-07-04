class AddAddAsReviewerToNotifications < ActiveRecord::Migration[5.0]

  def change
    add_column :notifications, :add_as_reviewer, :boolean, default: true
    Notification.where(add_as_collaborator: false).update_all(add_as_reviewer: false)
  end

end
