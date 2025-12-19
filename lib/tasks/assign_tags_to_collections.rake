namespace :fromthepage do
  desc 'Assign subject tags to collections retrospectively'
  task assign_tags_to_collections: :environment do |t|
    if ENABLE_OPENAI
      Collection.all.each do |collection|
        unless collection.intro_block.blank? || collection.tags.present? || collection.intro_block.length < 100
          collection.tags << Tag.tag_by_subject(collection.intro_block, collection.title)
        end
      end
    else
      puts 'This task requires OpenAI to be enabled.  Set the appropriate values in config/intializers/01fromthepage.rb'
    end
  end
end
