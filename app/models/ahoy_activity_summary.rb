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
class AhoyActivitySummary < ActiveRecord::Base
  KEEP_AFTER = 14.days

  WEEKLY_TRIAL_COHORT_TARGET_ACTIONS = [
    'collection#create',
    'registrations#create',
    'registrations#new_trial',
    'static#landing_page'
  ]

  WEEKLY_TRANSCRIBER_COHORT_TARGET_ACTIONS = [
    'registrations#create',
    'registrations#new',
    'static#landing_page',
    'transcribe#display_page',
    'transcribe#save_transcription'
  ]
end
