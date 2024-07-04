class AddProvenanceToArticles < ActiveRecord::Migration[5.0]

  def change
    add_column :articles, :provenance, :string # filename and date
  end

end
