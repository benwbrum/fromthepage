namespace :fromthepage do
  namespace :export do
    desc 'Dump collections by SLUG (USAGE: rake fromthepage:export:collection_dump[slug-1,slug-2])'
    task :database_dump, [:slugs] => :environment do |_t, args|
      slugs = (args[:slugs] || '').split(',').map(&:strip)

      current_time = Time.current.to_i
      dump_path = Rails.root.join('tmp', 'dumps', current_time.to_s)
      Dir.mkdir(dump_path) unless Dir.exist?(dump_path)

      puts 'Dumping database'

      result = Database::Export::DumpBuilder.new(
        collection_slugs: slugs,
        path: dump_path
      ).call

      puts 'Finished with errors' unless result.success?
    end
  end
end
