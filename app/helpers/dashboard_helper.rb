module DashboardHelper

  def time_ago(time)
    delta_seconds = (Time.new - time).floor
    delta_minutes = (delta_seconds / 60).floor
    delta_hours = (delta_minutes / 60).floor
    delta_days = (delta_minutes / 24).floor
    
    if delta_days > 1
      "#{delta_days} days ago"
    elsif delta_days == 1
      "1 day ago"
    elsif delta_hours > 1
      "#{delta_hours} hours ago"
    elsif delta_hours == 1
      "1 hour ago"
    elsif delta_minutes > 1
      "#{delta_minutes} minutes ago"
    elsif delta_minutes == 1
      "1 minute ago"
    elsif delta_seconds > 1
      "#{delta_seconds} seconds ago"
    else
      "1 second ago"
    end
  end

end
