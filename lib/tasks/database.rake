require 'fileutils'

namespace :fromthepage do
  namespace :export do
    desc 'Dump collections by SLUG (USAGE: rake fromthepage:export:database_dump[slug-1,slug-2])'
    task :database_dump, [ :slugs ] => :environment do |_t, args|
      slugs = (args[:slugs] || '').split(',').map(&:strip)

      current_time = Time.current.to_i
      dump_path = Rails.root.join('tmp', 'dumps', current_time.to_s)
      FileUtils.mkdir_p(dump_path)

      puts 'Dumping database'

      result = Database::Export::DumpBuilder.new(
        collection_slugs: slugs,
        path: dump_path
      ).call

      puts "Finished with errors: #{result.full_errors}\n#{result.full_errors.backtrace.join("\n")}" unless result.success?
    end
  end

  namespace :import do
    desc 'Import collections dump (USAGE: rake fromthepage:import:database_dump[path_to_dump])'
    task :database_dump, [ :path_to_dump ] => :environment do |_t, args|
      path_to_dump = args[:path_to_dump]
      path = Rails.root.join('tmp', 'dumps', path_to_dump)

      if File.exist?(path)
        puts 'Importing dump to database'

        result = Database::Import::DumpIngestor.new(path: path).call

        puts "Finished with errors: #{result.full_errors}\n#{result.full_errors.backtrace.join("\n")}" unless result.success?
      else
        puts 'Path to dump does not exist'
      end
    end
  end
end
