class AddCollectionAndDocumentSetCounterCacheCols < ActiveRecord::Migration[5.2]
  def up
    add_column :collections, :works_count, :integer, default: 0
    add_column :document_sets, :works_count, :integer, default: 0

    puts "Setting Collection Work Counts..."
    Collection.all.each do |c|
      Collection.reset_counters c.id, :works
    end

    puts "Setting DocumentSet Work Counts..."
    DocumentSet.all.each do |ds|
      DocumentSet.reset_counters ds.id, :document_set_works
    end
  end
  def down
    remove_column :collections, :works_count, :integer
    remove_column :document_sets, :works_count, :integer
  end
end
