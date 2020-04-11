module UserCollectionTime
    def self.total_contiguous_seconds(times, tolerance=60.minutes)
        
        total_seconds = 0
        from_time = nil

        for time in times.sort do
            time_diff = from_time.nil? ? 0 : (time - from_time).round
            total_seconds += time_diff if time_diff < tolerance
            from_time = time
        end
        return total_seconds
    end
end