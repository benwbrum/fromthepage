class AddVersionToScManifest < ActiveRecord::Migration[6.0]

  def change
    add_column :sc_manifests, :version, :string, default: '2'
  end

end
