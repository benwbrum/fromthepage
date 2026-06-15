# Helper module for collection copy operations
module CollectionCopyHelper
  # Copy uploaded page image files to prevent sharing between collections
  def self.copy_page_image_files(source_page, target_page)
    # Only copy files for uploaded images (not IIIF or Internet Archive)
    return if !source_page.image.attached? && source_page.base_image.blank?
    return if source_page.sc_canvas.present?
    return if source_page.ia_leaf.present?

    if source_page.image.attached?
      target_page.image.attach(source_page.image.blob)
    else
      source_base_image = source_page.base_image
      source_base_path = File.join(Rails.root, 'public', source_base_image.sub(/.*public/, ''))

      # Only copy if the source file exists
      return unless File.exist?(source_base_path)

      # Generate target filename with new page id
      ext = File.extname(source_base_path)
      content_type =
        case ext
        when '.jpg', '.jpeg'
          'image/jpeg'
        when '.png'
          'image/png'
        when '.gif'
          'image/gif'
        when '.webp'
          'image/webp'
        else
          'application/octet-stream'
        end

      File.open(source_base_path) do |file|
        target_page.image.attach(
          io: file,
          filename: File.basename(source_base_path),
          content_type: content_type
        )
      end
    end

    target_page.thumbnail_image
    target_page.reload
    puts "Copied image files for page #{source_page.id} to page #{target_page.id}"
  end
end

namespace :fromthepage do
  # code to copy a collection into a new collection owned by the same user, with subjects, works, and pages
  namespace :copy do
    desc 'Copy a collection into a new collection owned by the same user, with subjects, works, and pages'
    task :collection, [:source_collection_slug, :target_collection_slug] => :environment do |t, args|
      source_collection_slug = args.source_collection_slug
      target_collection_slug = args.target_collection_slug
      source_collection = Collection.find_by(slug: source_collection_slug)
      target_collection = Collection.find_by(slug: target_collection_slug)
      if source_collection.nil? || target_collection.nil?
        puts 'Usage: rake fromthepage:copy:collection[source_collection_slug,target_collection_slug]'
        puts '  source_collection_slug: slug of the collection to copy from'
        puts '  target_collection_slug: slug of the collection to copy to'
        exit
      end
      owner = source_collection.owner
      Current.user = owner
      category_map = {}
      target_collection.categories.delete_all
      # categories are in a tree; we want to walk the tree and duplicate each category and its parent
      source_collection.categories.where(parent_id: nil).each do |category|
        # if the category is already in the map, skip it
        if category_map[category.id]
          puts "Skipping category #{category.id} (#{category.title}) because it is already in the map"
          next
        else
          puts "Copying category #{category.id} (#{category.title})"
        end
        # create a new category with the same title and parent
        new_category = Category.new(title: category.title, collection: target_collection)
        new_category.collection = target_collection
        new_category.parent = category_map[category.parent_id]
        puts "#{new_category.valid?}: #{new_category.errors.full_messages} \n #{new_category.inspect}"
        new_category.save!
        # add the new category to the map
        category_map[category.id] = new_category
      end

      source_collection.categories.where.not(parent_id: nil).each do |category|
        # if the category is already in the map, skip it
        if category_map[category.id]
          puts "Skipping category #{category.id} (#{category.title}) because it is already in the map"
          next
        else
          puts "Copying category #{category.id} (#{category.title})"
        end
        # create a new category with the same title and parent
        new_category = Category.new(title: category.title, collection: target_collection)
        new_category.collection = target_collection
        new_category.parent = category_map[category.parent_id]
        puts "#{new_category.valid?}: #{new_category.errors.full_messages} \n #{new_category.inspect}"
        new_category.save
        # add the new category to the map
        category_map[category.id] = new_category
      end

      # now copy the articles
      source_collection.articles.each do |article|
        # create a new article with the same title, source_text, and other attributes
        new_article = article.dup
        new_article.collection = target_collection
        # now replace each category with the corresponding category
        new_article.categories = article.categories.map do |category|
          # find the corresponding category in the map
          category_map[category.id]
        end
        new_article.xml_text = ''
        new_article.source_text = ''

        new_article.source_text = article.source_text || ''
      end

      # now copy the works
      source_collection.works.each do |work|
        # duplicate the work
        original_attributes = work.attributes.dup
        original_attributes.delete('slug')
        original_attributes.delete('id')
        new_work = Work.new(original_attributes)
        new_work.collection = target_collection
        new_work.save!

        # now copy the pages
        work.pages.each do |page|
          page_attributes = page.attributes.dup
          page_attributes.delete('id')
          page_attributes.delete('status')
          new_page = Page.new(page_attributes)
          new_page.status = page.status
          new_page.source_text = ''
          new_page.xml_text = ''
          new_work.pages << new_page

          # now re-save the page with the original source text and status to fix the versions
          new_page.source_text = page.source_text || ''
          new_page.status = page.status
          new_page.save!

          # Copy uploaded image files to prevent sharing between collections
          CollectionCopyHelper.copy_page_image_files(page, new_page)
        end
      end
    end
  end
end
