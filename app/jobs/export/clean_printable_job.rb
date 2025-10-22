class Export::CleanPrintableJob < RecurringBaseJob
  queue_as :default

  def perform(temp_dir: 'tmp/printable')
    temp_dir = Rails.root.join(temp_dir)
    return unless Dir.exist?(temp_dir)

    cutoff_time = 1.week.ago.beginning_of_day.utc
    Dir.glob("#{temp_dir}/*").each do |dir_path|
      next unless File.directory?(dir_path)

      folder_name = File.basename(dir_path)

      begin
        folder_time = Time.strptime(folder_name, '%Y%m%d%H%M%S')
      rescue ArgumentError => _e
        next
      end

      FileUtils.rm_rf(dir_path) if folder_time < cutoff_time
    end
  end
end
