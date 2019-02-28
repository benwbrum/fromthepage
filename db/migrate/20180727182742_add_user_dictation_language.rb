class AddUserDictationLanguage < ActiveRecord::Migration
  def change
    add_column :users, :dictation_language, :string, :default => 'en-US'
  end
end
