class AddDescriptionInstructionsToCollections < ActiveRecord::Migration[6.0]

  def change
    add_column :collections, :description_instructions, :text
  end

end
