class AddOrgFieldsEnabledToCategories < ActiveRecord::Migration[6.1]
  def change
    add_column :categories, :org_fields_enabled, :boolean
  end
end
