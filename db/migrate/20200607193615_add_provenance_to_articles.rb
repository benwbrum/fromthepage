class AddProvenanceToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :provenance, :string # filename and date
  end
end
