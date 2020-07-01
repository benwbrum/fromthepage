class AddPrefix < ActiveRecord::Migration
  def change
    add_column :ontologies, :prefix, :string
  end
end