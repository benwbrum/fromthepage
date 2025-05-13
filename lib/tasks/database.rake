require 'fileutils'

namespace :fromthepage do
  namespace :export do
    desc 'Dump collections by SLUG (USAGE: rake fromthepage:export:database_dump[slug-1,slug-2])'
    task :database_dump, [:slugs] => :environment do |_t, args|
      slugs = (args[:slugs] || '').split(',').map(&:strip)

      current_time = Time.current.to_i
      dump_path = Rails.root.join('tmp', 'dumps', current_time.to_s)
      FileUtils.mkdir_p(dump_path)

      puts 'Dumping database'

      result = Database::Export::DumpBuilder.new(
        collection_slugs: slugs,
        path: dump_path
      ).call

      puts "Finished with errors\n#{result.full_errors}" unless result.success?
    end
  end
end
