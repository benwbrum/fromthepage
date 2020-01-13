class ChangeLabelSizeInScManifests < ActiveRecord::Migration[5.2]
  def up
    change_column :sc_manifests, :label, :text, :limit => 512
  end
  def down
    change_column :sc_manifests, :label, :string
  end
end
