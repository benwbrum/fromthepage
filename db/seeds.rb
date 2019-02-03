# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)


# ## Deeds
# author = User.first
# author_collection = author.collections.last
# author_work = collection.works.first
# author_page = work.pages.last
#
# author_deed = Deed.new
# author_deed.deed_type = DeedType::WORK_ADDED
# author_deed.page_id = author_page.id
# author_deed.work_id = author_work.id
# author_deed.collection_id = author_collection.id
# author_deed.user_id = author.id
# author_deed.save!
#
# contributor = User.find(9)
# contributor_work = collection.works.last
# contributor_page = contributor_work.pages.first
#
# contributor_deed1 = Deed.new
# contributor_deed1.deed_type = DeedType::WORK_ADDED
# contributor_deed1.page_id = contributor_page.id
# contributor_deed1.work_id = contributor_work.id
# contributor_deed1.collection_id = author_collection.id
# contributor_deed1.user_id = contributor.id
# contributor_deed1.save!
#
# contributor_deed2 = Deed.new
# contributor_deed2.deed_type = DeedType::PAGE_TRANSLATED
# contributor_deed2.page_id = author_page.id
# contributor_deed2.work_id = author_work.id
# contributor_deed2.collection_id = author_collection.id
# contributor_deed2.user_id = contributor.id
# contributor_deed2.save!
