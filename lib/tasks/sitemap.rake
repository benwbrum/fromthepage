namespace :fromthepage do
  namespace :sitemap do
    desc 'Generate static sitemap files for better archival discovery'
    task generate: :environment do
      require 'fileutils'

      sitemap_dir = Rails.root.join('public', 'sitemaps')
      FileUtils.mkdir_p(sitemap_dir)

      # Configuration
      base_url = Rails.application.config.force_ssl ? 'https://fromthepage.com' : 'http://localhost:3000'
      max_urls_per_file = 50000

      puts 'Generating sitemaps...'

      # Generate collections sitemap
      generate_collections_sitemap(sitemap_dir, base_url, max_urls_per_file)

      # Generate works sitemap
      generate_works_sitemap(sitemap_dir, base_url, max_urls_per_file)

      # Generate pages sitemap
      generate_pages_sitemap(sitemap_dir, base_url, max_urls_per_file)

      # Generate sitemap index
      generate_sitemap_index(sitemap_dir, base_url)

      puts "Sitemaps generated successfully in #{sitemap_dir}"
    end

    private

    def generate_collections_sitemap(sitemap_dir, base_url, max_urls_per_file)
      collections = Collection.where(restricted: false)
                             .includes(:owner)
                             .order(:id)

    file_count = (collections.count.to_f / max_urls_per_file).ceil

    collections.each_slice(max_urls_per_file).with_index do |slice, index|
      filename = file_count > 1 ? "sitemap_collections_#{index + 1}.xml" : 'sitemap_collections.xml'
      File.open(File.join(sitemap_dir, filename), 'w') do |file|
        file.write(generate_xml_header)

        slice.each do |collection|
          if collection.owner
            url = "#{base_url}/#{collection.owner.slug}/#{collection.slug}"
            lastmod = (collection.most_recent_deed_created_at || collection.created_on || Time.now).strftime('%Y-%m-%d')

            file.write(generate_url_entry(url, lastmod, 'weekly', '0.8'))
          end
        end

        file.write(generate_xml_footer)
      end
    end
  end

  def generate_works_sitemap(sitemap_dir, base_url, max_urls_per_file)
    works = Work.joins(:collection)
               .where(collections: { restricted: false })
               .includes(collection: :owner)
               .order(:id)

    file_count = (works.count.to_f / max_urls_per_file).ceil

    works.each_slice(max_urls_per_file).with_index do |slice, index|
      filename = file_count > 1 ? "sitemap_works_#{index + 1}.xml" : 'sitemap_works.xml'
      File.open(File.join(sitemap_dir, filename), 'w') do |file|
        file.write(generate_xml_header)

        slice.each do |work|
          if work.collection && work.collection.owner
            url = "#{base_url}/#{work.collection.owner.slug}/#{work.collection.slug}/#{work.slug}"
            lastmod = (work.most_recent_deed_created_at || work.created_on || Time.now).strftime('%Y-%m-%d')

            file.write(generate_url_entry(url, lastmod, 'weekly', '0.7'))
          end
        end

        file.write(generate_xml_footer)
      end
    end
  end

  def generate_pages_sitemap(sitemap_dir, base_url, max_urls_per_file)
    pages = Page.joins(work: :collection)
               .where(collections: { restricted: false })
               .where.not(status: [ 'blank', 'new' ])
               .includes(work: { collection: :owner })
               .order(:id)

    file_count = (pages.count.to_f / max_urls_per_file).ceil

    pages.each_slice(max_urls_per_file).with_index do |slice, index|
      filename = file_count > 1 ? "sitemap_pages_#{index + 1}.xml" : 'sitemap_pages.xml'
      File.open(File.join(sitemap_dir, filename), 'w') do |file|
        file.write(generate_xml_header)

        slice.each do |page|
          url = "#{base_url}/#{page.work.collection.owner.slug}/#{page.work.collection.slug}/#{page.work.slug}/display/#{page.id}"
          lastmod = (page.updated_at || page.created_on || Time.now).strftime('%Y-%m-%d')

          file.write(generate_url_entry(url, lastmod, 'monthly', '0.6'))
        end

        file.write(generate_xml_footer)
      end
    end
  end

  def generate_sitemap_index(sitemap_dir, base_url)
    File.open(File.join(sitemap_dir, 'sitemap.xml'), 'w') do |file|
      file.write('<?xml version="1.0" encoding="UTF-8"?>')
      file.write('<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')

      # Find all sitemap files and add them to index
      Dir.glob(File.join(sitemap_dir, 'sitemap_*.xml')).sort.each do |sitemap_file|
        filename = File.basename(sitemap_file)
        file.write('<sitemap>')
        file.write("<loc>#{base_url}/sitemaps/#{filename}</loc>")
        file.write("<lastmod>#{Time.now.strftime('%Y-%m-%d')}</lastmod>")
        file.write('</sitemap>')
      end

      file.write('</sitemapindex>')
    end

    # Copy main sitemap to public root
    FileUtils.cp(File.join(sitemap_dir, 'sitemap.xml'), Rails.root.join('public', 'sitemap.xml'))
  end

  def generate_xml_header
    '<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  end

  def generate_xml_footer
    '</urlset>'
  end

  def generate_url_entry(url, lastmod, changefreq, priority)
    "<url><loc>#{url}</loc><lastmod>#{lastmod}</lastmod><changefreq>#{changefreq}</changefreq><priority>#{priority}</priority></url>"
  end
  end
end
