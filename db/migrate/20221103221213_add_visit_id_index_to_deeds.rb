class AddVisitIdIndexToDeeds < ActiveRecord::Migration[6.0]

  def change
    add_index :deeds, :visit_id
  end

end
