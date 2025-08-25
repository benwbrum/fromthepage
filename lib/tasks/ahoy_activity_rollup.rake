require 'ahoy_activity_utils'
namespace :fromthepage do
  desc 'Daily Task to Rollup Ahoy Events into Transcribe minutes by Date, User, and Collection'
  task summarize_ahoy_activity_for_date: :environment do
    AhoyActivityUtils.rollup_transcribe_for_date()
  end

  desc 'Run/Re-run summarize task for the past N days'
  task :summarize_ahoy_activity_for_last_n_days, [ :days ] => :environment do |task, args|
    since = args[:days].to_i

    # Count back from yesterday into the past N days
    (1..since).each do |n|
      date = n.days.ago.beginning_of_day

      print "\n-- Ahoy Rollup #{date.strftime("%Y-%m-%d")} --\n"

      # Perform the rollup for the day
      AhoyActivityUtils.rollup_transcribe_for_date(date)
    end
  end

  desc 'An ad-hoc task to populate the ahoy rollup for historical data'
  task summarize_all_ahoy_activity: :environment do
    ## Figure out how long we need to count back (to the first Ahoy Event)
    first_ahoy_event = Ahoy::Event.order(:time).limit(1).pluck(:time).first.beginning_of_day
    days = ((Time.now.beginning_of_day - first_ahoy_event) / 60 / 60 / 24).to_i


    # Count back from yesterday into the past
    (1..days).each do |n|
      date = n.days.ago.beginning_of_day

      print "\n-- Ahoy Rollup #{date.strftime("%Y-%m-%d")} --\n"

      # Perform the rollup for the day
      AhoyActivityUtils.rollup_transcribe_for_date(date)
    end
  end
end
