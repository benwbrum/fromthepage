# == Schema Information
#
# Table name: metadata_description_versions
#
#  id                   :integer          not null, primary key
#  metadata_description :text(65535)
#  version_number       :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  user_id              :integer          not null
#  work_id              :integer          not null
#
# Indexes
#
#  index_metadata_description_versions_on_user_id  (user_id)
#  index_metadata_description_versions_on_work_id  (work_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (work_id => works.id)
#
class MetadataDescriptionVersion < ApplicationRecord
  belongs_to :user
  belongs_to :work

  def display
    self.created_at.strftime('%b %d, %Y') + ' - ' + self.user.display_name + " (#{self.version_number})"
  end
end
