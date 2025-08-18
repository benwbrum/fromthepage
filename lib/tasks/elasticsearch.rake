require 'json'

namespace :fromthepage do
  namespace :es do
    namespace :setup do
      desc 'Initialize Elasticsearch configuration'
      task init: :environment do
        def parse_es_config(target:, format: :json)
          target = ['lib', 'elastic'] + target
          src = File.read(File.join(Rails.root.join(*target)))

          return src unless format == :json

          JSON.parse(src)
        end

        client = Chewy.client

        response = client.indices.put_template(
          name: 'fromthepage',
          body: parse_es_config(target: ['schema', 'template.json'])
        )

        raise 'Failed to apply template' unless response['acknowledged']

        response = client.put_script(
          id: 'multilingual_content',
          body: {
            script: {
              lang: 'painless',
              source: parse_es_config(target: ['scripts', 'multilingual_content.painless'], format: :txt)
            }
          }
        )

        raise 'Failed to apply script' unless response['acknowledged']

        response = client.ingest.put_pipeline(
          id: 'multilingual',
          body: parse_es_config(target: ['pipeline', 'multilingual.json'])
        )

        raise 'Failed to apply pipeline' unless response['acknowledged']
      end

      desc 'Clean up Elasticsearch components'
      task cleanup: :environment do
        CollectionsIndex.delete
        PagesIndex.delete
        WorksIndex.delete
        UsersIndex.delete

        client = Chewy.client

        begin
          client.delete_script(id: 'multilingual_content')
        rescue StandardError => _e
          puts 'Multilingual content script not found'
        end

        begin
          client.ingest.delete_pipeline(id: 'multilingual')
        rescue StandardError => _e
          puts 'Multilingual pipeline not found'
        end

        begin
          client.indices.delete_template(name: 'fromthepage')
        rescue StandardError => _e
          puts 'Indices template not initialized'
        end
      end
    end

    namespace :data do
      desc 'Create Elasticsearch indices'
      task build: :environment do
        CollectionsIndex.create
        # DocumentSets have same name with collection so no need to recreate
        PagesIndex.create
        WorksIndex.create
        UsersIndex.create
      end

      desc 'Reindex elements'
      task :reindex, [:hours_ago] => :environment do |t, args|
        collections_scope = Collection.includes(:owner)
        document_sets_scope = DocumentSet.includes(:owner, :collection)
        works_scope = Work.includes({ collection: :owner }, :document_sets)
        users_scope = User.all
        pages_scope = Page.includes(work: [{ collection: :owner }, :document_sets])

        if args[:hours_ago]
          hours_ago = args[:hours_ago].to_i
          time_threshold = Time.current - hours_ago.hours

          puts "Scoping reindex to records updated_at >= #{hours_ago} hours ago"

          collections_scope = collections_scope.where('most_recent_deed_created_at >= ?', time_threshold)
          document_sets_scope = document_sets_scope.where('updated_at >= ?', time_threshold)
          works_scope = works_scope.where('most_recent_deed_created_at >= ?', time_threshold)
          users_scope = users_scope.where('updated_at >= ?', time_threshold)
          pages_scope = pages_scope.where('updated_at >= ?', time_threshold)
        end

        CollectionsIndex.import collections_scope
        DocumentSetsIndex.import document_sets_scope
        WorksIndex.import works_scope
        UsersIndex.import users_scope
        PagesIndex.import pages_scope
      end

      desc 'Delete Elasticsearch indices'
      task reset: :environment do
        CollectionsIndex.purge
        PagesIndex.purge
        WorksIndex.purge
        UsersIndex.purge
      end

      desc 'Gets Elasticsearch indices data'
      task stats: :environment do
        def format_index_line(idx)
          name = idx['index'].ljust(32)
          "#{name}#{idx['health']}\t#{idx['status']}\t#{idx['docs.count']} documents"
        end

        client = Chewy.client
        suffix = ENV['ELASTIC_SUFFIX']
        all_indices = client.cat.indices(format: 'json')

        if suffix
          current = all_indices.select { |idx| idx['index'].end_with?(suffix) }
          puts 'Current index stats:'
          current.each { |idx| puts format_index_line(idx) }
          puts
        end

        puts 'All index stats:'
        all_indices.each { |idx| puts format_index_line(idx) }
      end

      desc 'Querries Elasticsearch via ID'
      task :query, [:id] => :environment do |_, args|
        id = args[:id]
        unless id
          puts 'Usage: rake fromthepage:es:data:query[ID]'
          exit 1
        end
      end
    end
  end
end
