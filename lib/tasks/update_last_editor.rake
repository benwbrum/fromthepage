namespace :fromthepage do
  desc 'update last_editor_user_id for pages in collections [first_id,last_id]'
  task :update_last_editor, [:first_id, :last_id] => :environment do |_t, args|
    Collection.where('id between ? and ?', args[:first_id].to_i, args[:last_id].to_i).each do |collection|
      print "#{collection.slug}\n"
      collection.pages.all.each do |page|
        unless page.current_version
          current_version = page.page_versions.first
          page.update_columns(page_version_id: current_version.id) if current_version
        end

        unless page.last_editor_user_id
          version = page.current_version
          if version
            user = version.user
            page.update_column(:last_editor_user_id, user.id) if user
          end
        end

        next if page.approval_delta

        next unless Page::COMPLETED_STATUSES.include?(page.status)

        most_recent_not_approver_version = page.page_versions.where(user_id: page.last_editor_user_id).first
        if most_recent_not_approver_version
          old_transcription = most_recent_not_approver_version.transcription
        else
          old_transcription = ''
        end
        new_transcription = page.source_text

        next if old_transcription.blank?

        approval_delta =
          Text::Levenshtein.distance(old_transcription,
            new_transcription).fdiv((old_transcription.size + new_transcription.size))
        page.update_column(:approval_delta, approval_delta)
      end
    end
  end
end
