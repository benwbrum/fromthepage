class ChangeLabelSizeInScManifests < ActiveRecord::Migration
  def up
    change_column :sc_manifests, :label, :text, :limit => 512
  end
  def down
    change_column :sc_manifests, :label, :string
  end
end
