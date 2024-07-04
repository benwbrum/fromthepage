class RetireImageSets < ActiveRecord::Migration[5.0]

  def change
    drop_table(:image_sets) if table_exists?(:image_sets)
    return unless table_exists?(:titled_images)

    drop_table(:titled_images)
  end

end
