class ChangeSlugToMbgId < ActiveRecord::Migration[6.0]
  def change
    #    remove_column :collections, :messageboard_slug, :string
    add_reference :collections, :thredded_messageboard_group, null: true, foreign_key: true
  end
end
