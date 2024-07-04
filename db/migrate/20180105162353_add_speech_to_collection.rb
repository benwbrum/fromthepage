class AddSpeechToCollection < ActiveRecord::Migration[5.0]

  def change
    add_column :collections, :voice_recognition, :boolean, default: false
    add_column :collections, :language, :string
  end

end
