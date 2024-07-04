class AddDescriptionStatusToWork < ActiveRecord::Migration[5.0]

  def change
    add_column :works, :description_status, :string, default: Work::DescriptionStatus::UNDESCRIBED
  end

end
