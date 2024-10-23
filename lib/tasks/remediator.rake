namespace :fromthepage do
  namespace :remediator do
    desc "Fixes deleted subjects and update references"



    task :fix_subjects, [:collection_id] => :environment do |t, args|
      User.current_user = User.find(2)
      collection = Collection.find(args.collection_id.to_i)
    
      # Remediation script
      # First, find all the articles that have been deleted
      # Find the pages that point to them
      missing_article_hash = find_deleted_articles_and_references(collection)
      # For each deleted article, 
      # * Find the lowest ID in the orphan references (that's the old ID, which external things like CWRGM ID will point to
      # * Find the corresponding new article (if one exists)
      #   ? Create an article at the old ID with the old title (note--we may need to rename a new article because of uniqueness constraints)
      #   ? find references to the orphan article and save those pages, which automatically will point to the recreated article because of title matching
      #   ? Save / fix pages with pointers to the new/bad articles
      #   ? delete the new articles (should we check for content? & categorization -- copy to new-old article)

      # new_article is the one created by the bug
      # replacement_article is the one we're recreating and pointing everything to
      # binding.pry
      redundent_reference_pages=[]
      # now we have a list of all of our problems (well, maybe not _all_ of them)
      missing_article_hash.each_pair do |title, entry|
        # what's the minimum ID of the references?
        min_id = entry[:ids].min
        # did we already create an article at that ID?
        unless Article.where(id: min_id).exists?
          # does the new article have content?
          replacement_article = Article.new(id: min_id, title: title, collection: collection, created_by_id: 2)
          if entry[:new_article]
            redundant_article=entry[:new_article]
            redundent_reference_pages+=redundant_article.pages.to_a
            replacement_article.source_text = redundant_article.source_text 
            # TODO all the things that the existing dedup merge code does here
            # rename the redundant article to something that won't conflict
            
            # copy the categories from the redundant article to the replacement article
            for category in redundant_article.categories
              replacement_article.categories << category
            end
            # copy the lat/lon coordinates from the redundant article to the replacement article
            replacement_article.latitude = redundant_article.latitude
            replacement_article.longitude = redundant_article.longitude
            # copy the source text from the redundant article to the replacement article
            replacement_article.source_text = redundant_article.source_text
            print "\nDestroying redundant article #{redundant_article.id}\t#{redundant_article.title}\n"
            redundant_article.destroy!
          end
          print "\nSaving replacement article!\n"
          pp replacement_article.attributes
          pp replacement_article.categories.map(&:title)
          replacement_article.save! # actually create the article at the old ID
        end
      end

      # now that we have appropriate articles, we want to update the references
      # references to the original missing article ID will be correct in XML but not in page_article_links
      # references to intermediate missing articles (Joseph Smith Jr. case) will be wrong in both
      # Ideally we'd "just resave the pages"


      # why are page_article_links not getting updated when we save the pages?  Why are the bad links not being updated?

      # TODO -- we need to delete the redundant articles -- before? -- after we are done updating pages
      # TODO -- test intermediate articles
      
      # get the unique pages that reference missing articles
      pages = missing_article_hash.values.map { |entry| entry[:pages] }.flatten + redundent_reference_pages
      pages = pages.uniq
      # for each page, resave the page so we get updated page source and page article links
      pages.each do |page|
        print "\nResaving page #{page.title}\n"
        # print the page_article_link count before and after
        print "Before: #{page.page_article_links.count} links\n"
        page.source_text+=' '
        page.save!
        print "After: #{page.page_article_links.count} links\n"
      end
    end


    def find_deleted_articles_and_references(collection)
      # track missing articles with a key of canonical title, and contents listing the ids pointed to, pages referencing them, and the new article (if any)
      missing_article_hash = {}

      collection.pages.each do |page|
        print "."
        unless page.xml_text.blank?
      #    page_url="#{url_stub}/#{page.work.slug}/#{page.id}"
          doc = REXML::Document.new(page.xml_text)
          doc.elements.each("//link") do |e|
            title = e.attributes['target_title']
            id = e.attributes['target_id']
            article = collection.articles.where(id: id.to_i).first
            if article.nil?
              # this is a reference to a missing article
              new_article = collection.articles.where(title: title).first
              # now we have a reference to a missing article, including title and id, as well as (possibly) the new article that replaced it
              entry = missing_article_hash[title]
              if entry.nil?
                entry={ :ids => [], :new_article => nil, :pages => [] }
              end
              entry[:ids] << id.to_i
              entry[:pages] << page
              entry[:new_article] = new_article if new_article
              missing_article_hash[title]=entry
            end
          end
        end
      end
      missing_article_hash
    end

  end
end