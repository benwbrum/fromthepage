module DashboardHelper
  def dashboard_set_title
    case
    when is_active_link?(dashboard_startproject_path)
      content_for :page_title, 'Start A Project - Owner Dashboard'
    when is_active_link?(dashboard_owner_path)
      content_for :page_title, 'Your Works - Owner Dashboard'
    when is_active_link?(dashboard_summary_path)
      content_for :page_title, 'Summary - Owner Dashboard'
    end
  end

  def time_spent_in_date_range(user_id, start_date, end_date)
    minutes_worked = minutes_worked_in_range(user_id, start_date, end_date)

    formatted_time(minutes_worked)
  end

  def minutes_worked_in_range(user_id, start_date, end_date)
    AhoyActivitySummary
      .where(user_id: user_id)
      .where.not(collection_id: nil)
      .where('date >= ? AND date <= ?', start_date, end_date)
      .sum(:minutes)
  end

  def formatted_time(total_minutes)
    hours, minutes = total_minutes.divmod(60)
    "#{hours} hours and #{minutes} minutes"
  end
end
