class AddArticleUri < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :uri, :string
  end
end
