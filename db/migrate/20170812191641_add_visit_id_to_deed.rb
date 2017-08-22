class AddVisitIdToDeed < ActiveRecord::Migration
  def change
    add_column :deeds, :visit_id, :integer, :index => true
  end
end
