class UpdateNextUntranscribedPages < ActiveRecord::Migration[6.0]
  def change
    Work.all.each do |work|
      work.set_next_untranscribed_page
    end

    Collection.all.each do |collection|
      collection.document_sets.each do |document_set|
        document_set.set_next_untranscribed_page
      end
      collection.set_next_untranscribed_page
    end
  end
end
