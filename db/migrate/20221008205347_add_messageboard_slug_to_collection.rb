class AddMessageboardSlugToCollection < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :messageboard_slug, :string
  end
end
