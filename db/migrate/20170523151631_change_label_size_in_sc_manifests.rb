class ChangeLabelSizeInScManifests < ActiveRecord::Migration[5.0]

  def up
    change_column :sc_manifests, :label, :text, limit: 5.0
  end

  def down
    change_column :sc_manifests, :label, :string
  end

end
