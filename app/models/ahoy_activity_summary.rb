# == Schema Information
#
# Table name: ahoy_activity_summaries
#
#  id            :integer          not null, primary key
#  activity      :string(255)
#  date          :datetime
#  minutes       :integer
#  created_at    :datetime
#  updated_at    :datetime
#  collection_id :integer
#  user_id       :integer
#
# Indexes
#
#  ahoy_activity_day_user_collection  (date,collection_id,user_id,activity) UNIQUE
#
class AhoyActivitySummary < ApplicationRecord
end
