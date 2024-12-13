require 'google/cloud_vision_page_processor'
namespace :fromthepage do
  namespace :google do

    def process_page(page) # other parameters based on engine
      processor = Google::CloudVision::PageProcessor.new(page)
      processor.process_page
    end

    desc "Process an entire collection: collection_id, [all|unprocessed]"
    task :process_collection, [:collection_id, :page_filter, :model_id] => :environment do |t,args|
      raise "Google CloudVision is not enabled" unless defined?(GCV_ENABLED) && GCV_ENABLED
      if args.collection_id.match(/^\d+$/)
        collection = Collection.where(id: args.collection_id.to_i).first
      else
        collection = Collection.where(slug: args.collection_id).first
      end
      if collection.nil?
        collection = DocumentSet.where(slug: args.collection_id).first
        if collection.nil?
          collection = DocumentSet.where(id: args.collection_id.to_i).first
        end
      end
      if collection.nil?
        print "Collection or Document Set not found\n"
        exit
      end


      if args.page_filter.nil?
        page_filter = "all"
      else
        page_filter = args.page_filter
      end

      # if args.model_id.blank?
      #   model_id = PageProcessor::Model::TEXT_TITAN_I
      # else
      #   model_id=args.model_id.to_i
      # end
      collection.pages.each do |page|
        if page_filter=='all' || (page_filter=='unprocessed' && !page.has_alto?)
          print "#{page.id} "
          process_page(page)
        end
      end
    end

    desc "Process a work: work_id, [all|unprocessed]"
    task :process_work, [:work_id, :page_filter] => :environment do |t,args|
      raise "Google CloudVision is not enabled" unless defined?(GCV_ENABLED) && GCV_ENABLED
      if args.work_id.match(/^\d+$/)
        work = Work.find args.work_id.to_i
      else
        work = Work.find args.work_id
      end
      if args.page_filter.nil?
        page_filter = "all"
      else
        page_filter = args.page_filter
      end

      work.pages.each do |page|
        if page_filter=='all' || (page_filter=='unprocessed' && !page.has_alto?)
          print "#{page.id} "
          process_page(page)
        end
      end
    end

    desc "Process a single page: page_id"
    task :process_page, [:page_id] => :environment do |t,args|
      raise "Google CloudVision is not enabled" unless defined?(GCV_ENABLED) && GCV_ENABLED
      page = Page.find args.page_id.to_i
      process_page(page)
    end

  end
end