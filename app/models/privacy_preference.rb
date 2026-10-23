# == Schema Information
#
# Table name: privacy_preferences
#
#  id        :bigint           not null, primary key
#  analytics :boolean          default(FALSE), not null
#  marketing :boolean          default(FALSE), not null
#  recorded  :boolean          default(FALSE), not null
#  user_id   :integer          not null
#
# Indexes
#
#  index_privacy_preferences_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class PrivacyPreference < ApplicationRecord
  belongs_to :user
end
