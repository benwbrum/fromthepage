# == Schema Information
#
# Table name: notifications
#
#  id                  :integer          not null, primary key
#  add_as_collaborator :boolean          default(TRUE)
#  add_as_owner        :boolean          default(TRUE)
#  add_as_reviewer     :boolean          default(TRUE)
#  note_added          :boolean          default(TRUE)
#  owner_stats         :boolean          default(FALSE)
#  user_activity       :boolean          default(TRUE)
#  created_at          :datetime
#  updated_at          :datetime
#  user_id             :integer
#
class Notification < ApplicationRecord

  belongs_to :user, optional: true

end
