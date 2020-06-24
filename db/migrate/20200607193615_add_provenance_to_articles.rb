class AddProvenanceToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :provenance, :string # filename and date
  end
end
