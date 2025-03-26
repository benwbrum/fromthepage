class AddBioFieldsEnabledToCategories < ActiveRecord::Migration[5.0]
  def change
    add_column :categories, :bio_fields_enabled, :boolean, default:false
  end
end
