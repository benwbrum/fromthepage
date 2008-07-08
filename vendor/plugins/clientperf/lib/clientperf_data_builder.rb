module ClientperfDataBuilder
  def build_data_for_chart(results, start_time, periods, period_increment)
    max = 0
    padded_results = (0..periods).map do |delta|
      time_period = start_time + delta.send(period_increment)
      data = get_data_or_pad(time_period, results)
      max = data if data && data > max
      [time_period, data]
    end
    [padded_results, max]
  end
  
  def day_start_time
    ((ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now) + 1.hour - 1.day).change(:min => 0)
  end
  
  def month_start_time
    ((ActiveRecord::Base.default_timezone == :utc ? Time.now.utc : Time.now) + 1.day - 30.days).change(:hour => 0)
  end
  
  private
  
  def get_data_or_pad(point, results)
    data = results.detect {|p,d| point == p.to_time(ActiveRecord::Base.default_timezone)}
    data ? data[1].to_i : 0
  end
end