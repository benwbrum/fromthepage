class AddTextLanguageToCollection < ActiveRecord::Migration[5.0]

  def change
    add_column :collections, :text_language, :string
  end

end
