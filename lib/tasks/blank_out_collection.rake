namespace :fromthepage do
  desc "clear all data from a collection"
  task :blank_out_collection, [:collection_id] => :environment do |t,args|
    collection_id = args.collection_id
    collection = Collection.find_by(id: collection_id)
    collection.blank_out_collection
  end

end