require 'csv'

namespace :fromthepage do
  namespace :title_duplicates do
    desc 'Write a CSV report of duplicate article titles using the articles table collation'
    task :report, [:output_file] => :environment do |_task, args|
      output_file = args[:output_file].presence || Rails.root.join('tmp', 'duplicate_article_titles.csv')
      groups = duplicate_article_title_groups

      FileUtils.mkdir_p(File.dirname(output_file))
      CSV.open(output_file, 'wb') do |csv|
        csv << %w[collection_id collection_title canonical_article_id duplicate_article_id title]
        groups.each do |group|
          canonical_id, *duplicate_ids = group.fetch('article_ids').split(',').map(&:to_i).sort
          duplicate_ids.each do |duplicate_id|
            csv << [group['collection_id'], group['collection_title'], canonical_id, duplicate_id, group['title']]
          end
        end
      end

      puts "Reported #{groups.size} duplicate title groups to #{output_file}"
    end

    desc 'Rename duplicate article titles after writing a CSV audit report'
    task :reconcile, [:output_file] => :environment do |_task, args|
      output_file = args[:output_file].presence || Rails.root.join('tmp', 'duplicate_article_titles.csv')
      Rake::Task['fromthepage:title_duplicates:report'].reenable
      Rake::Task['fromthepage:title_duplicates:report'].invoke(output_file)

      duplicate_article_title_groups.each do |group|
        _canonical_id, *duplicate_ids = group.fetch('article_ids').split(',').map(&:to_i).sort
        duplicate_ids.each do |id|
          article = Article.find(id)
          suffix = " [duplicate #{id}]"
          reconciled_title = "#{article.title.to_s[0, 255 - suffix.length]}#{suffix}"
          counter = 2
          while collection_title_exists?(article, reconciled_title)
            suffix = " [duplicate #{id}-#{counter}]"
            reconciled_title = "#{article.title.to_s[0, 255 - suffix.length]}#{suffix}"
            counter += 1
          end
          article.update_column(:title, reconciled_title)
          puts "Renamed article #{id} to #{reconciled_title.inspect}"
        end
      end
    end
  end
end

def collection_title_exists?(article, title)
  article.collection.articles.where.not(id: article.id).exists?(title: title)
end

def duplicate_article_title_groups
  Article.connection.select_all(<<~SQL).to_a
    SELECT articles.collection_id,
           collections.title AS collection_title,
           MIN(articles.title) AS title,
           GROUP_CONCAT(articles.id ORDER BY articles.id) AS article_ids
      FROM articles
      LEFT JOIN collections ON collections.id = articles.collection_id
     WHERE articles.collection_id IS NOT NULL
     GROUP BY articles.collection_id, articles.title
    HAVING COUNT(*) > 1
     ORDER BY articles.collection_id, MIN(articles.id)
  SQL
end
