class ArticlesHaveGraphs < ActiveRecord::Migration[5.0]
  def self.up
    add_column :articles, :graph_image, :string
  end

  def self.down
    remove_column :articles, :graph_image
  end
end
