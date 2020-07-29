class AddXmlToArticle < ActiveRecord::Migration[5.0]
  def self.up
    add_column :articles, :xml_text, :text
  end

  def self.down
    remove_column :articles, :xml_text
  end
end
