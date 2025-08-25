namespace :fromthepage do
  desc 'Refresh metadata'
  task :refresh_metadata, [ :id, :type ] => :environment do |_task, args|
    id = args[:id]
    type = args[:type]

    raise ArgumentError, 'Usage: rake fromthepage:refresh_metadata[id_value,type_value]' if id.nil? || type.nil?

    puts 'NOTE: Logs will be handled by metadata refresh job — do not pipe this task’s output.'

    Metadata::RefreshJob.perform_now(id: id, type: type, user_id: nil)
  end
end
