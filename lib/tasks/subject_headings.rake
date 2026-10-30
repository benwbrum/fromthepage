namespace :fromthepage do
  desc 'Create a collection\'s Subject Heading Sample Set and queue AI subject heading drafts. Usage: [collection_id, user_login]'
  task :subject_heading_sample_set, [:collection_id, :user_login] => :environment do |_t, args|
    collection = Collection.find(args[:collection_id])
    user = args[:user_login].present? ? User.find_by!(login: args[:user_login]) : collection.owner

    SubjectHeadings::SampleSetJob.perform_now(user_id: user.id, collection_id: collection.id)

    sample_set = collection.document_sets.find_by!(title: SubjectHeadings::CreateSampleSet::TITLE)
    puts "Created \"#{sample_set.title}\" (#{sample_set.works.count} works) and queued AI drafts:"
    sample_set.works.each { |work| puts "  #{work.id} #{work.title}" }
  end
end
