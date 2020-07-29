class AddUserDictationLanguage < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :dictation_language, :string, :default => 'en-US'
  end
end
