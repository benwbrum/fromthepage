namespace :fromthepage do
  desc 'Refresh metadata'
  task :refresh_metadata, [:id, :type] => :environment do |_task, args|
    id = args[:id]
    type = args[:type]

    raise ArgumentError, 'Usage: rake fromthepage:refresh_metadata[id_value,type_value]' if id.nil? || type.nil?

    case type
    when 'collection'
      p "Refreshing metadata for works in collection #{id}"
      object = Collection.find_by(id: id)
      all_work_ids = object.works.pluck(:id)
    when 'document_set'
      p "Refreshing metadata for works in document_sets #{id}"
      object = DocumentSet.find_by(id: id)
      all_work_ids = object.works.pluck(:id)
    when 'work'
      p "Refreshing metadata for work #{id}"
      all_work_ids = [id]
    else
      raise ArgumentError, 'Type can only be collection, document_set, or work' if id.nil?
    end

    result = Work::RefreshMetadata.new(work_ids: all_work_ids).call

    if result.success?
      p 'Updated metadata successfully!'
    else
      p 'Refresh metadata finished with errors:'

      result.errors.each do |error|
        p error
      end
    end
  end
end
