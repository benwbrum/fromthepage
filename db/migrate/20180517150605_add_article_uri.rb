class AddArticleUri < ActiveRecord::Migration[5.0]

  def change
    add_column :articles, :uri, :string
  end

end
