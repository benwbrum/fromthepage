namespace :fromthepage do
  desc 'update line counts for pages and works [first_index,last_index]'
  task :update_line_counts, [:first_index, :last_index] => :environment do |_t, args|
    first_index = args.first_index.to_i
    last_index = args.last_index.to_i

    Collection.all.to_a[first_index..last_index].each do |collection|
      print "#{collection.slug}\n"
      collection.works.each do |work|
        print "\t#{work.slug}\n"
        work.pages.each do |page|
          print "\t\t#{page.id}\n"
          page.update_column(:line_count, page.calculate_line_count)
        end
        work.work_statistic.recalculate_from_hash
        GC.start
      end
    end
  end
end
