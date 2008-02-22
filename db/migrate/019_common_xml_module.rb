class CommonXmlModule < ActiveRecord::Migration
  def self.up
    rename_column :pages, :transcription, :source_text
    rename_column :pages, :xml_transcription, :xml_text
#    remove_column :pages, :display_transcription
  end

  def self.down
    rename_column :pages, :source_text, :transcription
    rename_column :pages, :xml_text, :xml_transcription
#    add_column :pages, :display_transcription, :text
  end
end
