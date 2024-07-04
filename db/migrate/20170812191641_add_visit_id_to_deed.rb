class AddVisitIdToDeed < ActiveRecord::Migration[5.0]

  def change
    add_column :deeds, :visit_id, :integer
  end

end
