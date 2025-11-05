class DeprecateArticlePagesCount < ActiveRecord::Migration[7.2]
  def change
    remove_column :articles, :pages_count
  end
end
