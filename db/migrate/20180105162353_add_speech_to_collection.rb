class AddSpeechToCollection < ActiveRecord::Migration
  def change
    add_column :collections, :voice_recognition, :boolean, default: false
    add_column :collections, :language, :string
  end
end
