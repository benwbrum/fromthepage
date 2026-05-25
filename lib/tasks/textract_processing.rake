namespace :fromthepage do
  namespace :textract do
    desc 'Process a single page with Amazon Textract'
    task :process_page, [:page_id] => :environment do |_t, args|
      unless args.page_id
        puts 'Usage: rake fromthepage:textract:process_page[page_id]'
        exit 1
      end

      page = Page.find(args.page_id.to_i)
      puts "Processing page #{page.id} (#{page.title}) with Amazon Textract"

      Textract::PageProcessor.new(page).process_page
      puts 'SUCCESS'
    end

    desc 'Process all pages in a work with Amazon Textract: work_id, [all|unprocessed]'
    task :process_work, [:work_id, :page_filter] => :environment do |_t, args|
      unless args.work_id
        puts 'Usage: rake fromthepage:textract:process_work[work_id,page_filter]'
        exit 1
      end

      work = if args.work_id.match?(/^\d+$/)
               Work.find(args.work_id.to_i)
      else
               Work.find(args.work_id)
      end

      page_filter = args.page_filter.presence || 'all'

      work.pages.each do |page|
        next unless page_filter == 'all' || (page_filter == 'unprocessed' && !page.has_alto?)

        print "#{page.id} "
        Textract::PageProcessor.new(page).process_page
      end
      puts
    end

    desc 'Process an entire collection or document set with Amazon Textract: collection_id, [all|unprocessed]'
    task :process_collection, [:collection_id, :page_filter] => :environment do |_t, args|
      unless args.collection_id
        puts 'Usage: rake fromthepage:textract:process_collection[collection_id,page_filter]'
        exit 1
      end

      collection = if args.collection_id.match?(/^\d+$/)
                     Collection.where(id: args.collection_id.to_i).first ||
                       DocumentSet.where(id: args.collection_id.to_i).first
      else
                     Collection.where(slug: args.collection_id).first ||
                       DocumentSet.where(slug: args.collection_id).first
      end

      if collection.nil?
        puts 'Collection or Document Set not found'
        exit 1
      end

      page_filter = args.page_filter.presence || 'all'

      collection.pages.each do |page|
        next unless page_filter == 'all' || (page_filter == 'unprocessed' && !page.has_alto?)

        print "#{page.id} "
        Textract::PageProcessor.new(page).process_page
      end
      puts
    end
  end
end
