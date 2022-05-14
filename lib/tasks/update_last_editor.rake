namespace :fromthepage do
  desc "update last_editor_user_id for pages in collections [first_id,last_id]"
  task :update_last_editor, [:first_id,:last_id] => :environment do |t,args|
    Collection.where('id between ? and ?', args[:first_id].to_i, args[:last_id].to_i).each do |collection|
      print "#{collection.slug}\n"
      collection.pages.all.each do |page|

        unless page.current_version
          current_version = page.page_versions.first
          if current_version
            page.update_columns(page_version_id: current_version.id)
          end
        end


        unless page.last_editor_user_id
          version = page.current_version
          if version
            user = version.user
            if user
              page.update_column(:last_editor_user_id, user.id)
            end
          end
        end

        unless page.approval_delta 
          if Page::COMPLETED_STATUSES.include? (page.status)
            most_recent_not_approver_version = page.page_versions.where(user_id: page.last_editor_user_id).first
            if most_recent_not_approver_version
              old_transcription = most_recent_not_approver_version.transcription
            else
              old_transcription = ''
            end
            new_transcription = page.source_text

            unless old_transcription.blank?
              approval_delta = 
                Text::Levenshtein.distance(old_transcription, new_transcription).to_f / (old_transcription.size + new_transcription.size).to_f
              page.update_column(:approval_delta, approval_delta)
            end
          end
        end
      end
    end
  end #end task
end #end namespace
