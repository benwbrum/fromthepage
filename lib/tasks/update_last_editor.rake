namespace :fromthepage do
  desc "update last_editor_user_id for pages in collections [first_id,last_id]"
  task :update_last_editor, [:first_id,:last_id] => :environment do |t,args|
    Collection.where('id between ? and ?', args[:first_id].to_i, args[:last_id].to_i).each do |collection|
      print "#{collection.slug}\n"
      collection.pages.all.each do |page|
        unless page.last_editor_user_id
          version = page.current_version
          if version
            user = version.user
            if user
              page.update_column(:last_editor_user_id, user.id)
            end
          end
        end
      end
    end
  end #end task
end #end namespace
