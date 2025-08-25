namespace :fromthepage do
  desc 'clear all data from a collection'
  task :blank_out_collection, [ :collection_id ] => :environment do |t, args|
    collection_id = args.collection_id
    collection = Collection.find_by(id: collection_id)

    puts "Reset all data in the #{collection.title} collection to blank"
    Collection::Blankout.new(collection: collection).call
    puts "#{collection.title} collection has been reset"
  end
end
