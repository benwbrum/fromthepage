namespace :fromthepage do
  desc "Update statistics from collections and document sets on deeds more recent than the max(document_set.updated_at)"
  task update_recent_stats: :environment do
    CollectionStatistic.update_recent_statistics
  end

end
