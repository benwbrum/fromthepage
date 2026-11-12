namespace :fromthepage do
  desc 'Draft a collection\'s sample set with AI metadata, including AI subject headings, as "Draft sample" on the AI settings tab does. Usage: [collection_id, user_login]'
  task :subject_heading_sample_set, [:collection_id, :user_login] => :environment do |_t, args|
    collection = Collection.find(args[:collection_id])
    user = args[:user_login].present? ? User.find_by!(login: args[:user_login]) : collection.owner

    SubjectHeadings::SampleSetJob.perform_now(user_id: user.id, collection_id: collection.id)

    run = collection.ai_work_metadata_runs.where(kind: 'sample').order(:id).last
    if run.waiting?
      puts 'Queued AI transcription for pages without it. The sample set is chosen and drafted once every page is transcribed.'
    else
      sample_set = AiWorkMetadata::StartRun.sample_set(collection)
      puts "Queued AI drafts for \"#{sample_set.title}\" (#{sample_set.works.count} works):"
      sample_set.works.each { |work| puts "  #{work.id} #{work.title}" }
    end
  end
end
