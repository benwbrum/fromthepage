class AddTextLanguageToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :text_language, :string
  end
end
