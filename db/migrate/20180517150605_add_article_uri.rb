class AddArticleUri < ActiveRecord::Migration
  def change
    add_column :articles, :uri, :string
  end
end
