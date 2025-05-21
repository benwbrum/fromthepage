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
      task reindex: :environment do
        CollectionsIndex.import Collection.includes(:owner)
        DocumentSetsIndex.import DocumentSet.includes(:owner, :collection)
        WorksIndex.import Work.includes({ collection: :owner }, :document_sets)
        UsersIndex.import User.all
        PagesIndex.import Page.includes(work: [{ collection: :owner }, :document_sets])
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
