class AddSemanticContributionSchemaType < ActiveRecord::Migration
  def change
    add_column :contributions, :schema_type, :string
  end
end
