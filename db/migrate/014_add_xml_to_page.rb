class AddXmlToPage < ActiveRecord::Migration
  def self.up
    add_column :pages, :xml_transcription, :text
  end

  def self.down
    remove_column :pages, :xml_transcription
  end
end
