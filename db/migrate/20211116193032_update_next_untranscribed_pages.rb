class UpdateNextUntranscribedPages < ActiveRecord::Migration[6.0]

  def change
    Work.all.each(&:set_next_untranscribed_page)

    Collection.all.each do |collection|
      collection.document_sets.each(&:set_next_untranscribed_page)
      collection.set_next_untranscribed_page
    end
  end

end
