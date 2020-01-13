# frozen_string_literal: true

class SetNextPageForCollectionsAndWorks < ActiveRecord::Migration[5.2]
  def change
    @works = Work.all
    @collections = Collection.all
    @docuement_sets = DocumentSet.all

    puts "Assigning Next Untranscribed Page to Works..."
    @works.each(&:set_next_untranscribed_page)
    print "done."

    puts "Assigning Next Untranscribed Page to Collections..."
    @collections.each(&:set_next_untranscribed_page)
    print "done."

    puts "Assigning Next Untranscribed Page to Document Sets..."
    @docuement_sets.each(&:set_next_untranscribed_page)
    print "done."
  end
end
