class ClientperfResult < ActiveRecord::Base
  belongs_to :clientperf_uri
  after_create :update_uri
  
  class << self
    include ClientperfDataBuilder

    def last_24_hours
      start_time = day_start_time
      results = average(:milliseconds, :conditions => ['created_at > ?', start_time], 
        :group => "date_format(created_at,'%Y-%m-%d %H')")

      build_data_for_chart(results, start_time, 23, :hours) 
    end

    def last_30_days
      start_time = month_start_time
      results = average(:milliseconds, :conditions => ['created_at > ?', start_time], 
        :group => "date_format(created_at,'%Y-%m-%d')")

      build_data_for_chart(results, start_time, 29, :days)
    end
  end
  
  private
  
  def update_uri
    clientperf_uri.update_attribute(:updated_at, Time.now)
  end
end