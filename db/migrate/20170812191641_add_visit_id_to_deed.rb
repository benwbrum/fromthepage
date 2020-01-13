class AddVisitIdToDeed < ActiveRecord::Migration[5.2]
  def change
    add_column :deeds, :visit_id, :integer, :index => true
  end
end
