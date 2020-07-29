class AddXmlToPage < ActiveRecord::Migration[5.0]
  def self.up
    add_column :pages, :xml_transcription, :text
  end

  def self.down
    remove_column :pages, :xml_transcription
  end
end
