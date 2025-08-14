namespace :fromthepage do
  # code to copy a collection into a new collection owned by the same user, with subjects, works, and pages
  namespace :copy do
    desc "Copy a collection into a new collection owned by the same user, with subjects, works, and pages"
    task :collection, [:source_collection_slug, :target_collection_slug] => :environment do |t,args|
      source_collection_slug = args.source_collection_slug
      target_collection_slug = args.target_collection_slug
      source_collection = Collection.find_by(slug: source_collection_slug)
      target_collection = Collection.find_by(slug: target_collection_slug)
      if source_collection.nil? || target_collection.nil?
        puts "Usage: rake fromthepage:copy:collection[source_collection_slug,target_collection_slug]"
        puts "  source_collection_slug: slug of the collection to copy from"
        puts "  target_collection_slug: slug of the collection to copy to"
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
          p "Skipping category #{category.id} (#{category.title}) because it is already in the map"
          next
        else
          p "Copying category #{category.id} (#{category.title})"
        end
        # create a new category with the same title and parent
        new_category = Category.new(title: category.title, collection: target_collection)
        new_category.collection=target_collection
        new_category.parent= category_map[category.parent_id]
        p "#{new_category.valid?}: #{new_category.errors.full_messages} \n #{new_category.inspect}"
        new_category.save!
        # add the new category to the map
        category_map[category.id] = new_category
      end

      source_collection.categories.where.not(parent_id: nil).each do |category|
        # if the category is already in the map, skip it
        if category_map[category.id]
          p "Skipping category #{category.id} (#{category.title}) because it is already in the map"
          next
        else
          p "Copying category #{category.id} (#{category.title})"
        end
        # create a new category with the same title and parent
        new_category = Category.new(title: category.title, collection: target_collection)
        new_category.collection=target_collection
        new_category.parent= category_map[category.parent_id]
        p "#{new_category.valid?}: #{new_category.errors.full_messages} \n #{new_category.inspect}"
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
        new_article.xml_text=''
        new_article.source_text = ''

        # if !new_article.save
        #   binding.pry
        # end

        new_article.source_text= article.source_text || ''
        # if !new_article.save
        #   binding.pry
        # end
      end

      # now copy the works
      source_collection.works.each do |work|
        # duplicate the work
        original_attributes = work.attributes.dup
        original_attributes.delete('slug')
        original_attributes.delete('id')
        new_work = Work.new(original_attributes)
        new_work.collection= target_collection
        new_work.save!

        # now copy the pages
        work.pages.each do |page|
          page_attributes = page.attributes.dup
          page_attributes.delete('id')
          page_attributes.delete('status')
          new_page = Page.new(page_attributes)
          new_page.status=page.status
          new_page.source_text=''
          new_page.xml_text=''
          new_work.pages << new_page || binding.pry

          # now re-save the page with the original source text and status to fix the versions
          new_page.source_text= page.source_text||''
          new_page.status= page.status
          new_page.save!
        end

      end
    end
  end
end
