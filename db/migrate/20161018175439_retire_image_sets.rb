class RetireImageSets < ActiveRecord::Migration
  def change
    if table_exists?(:image_sets)
      drop_table(:image_sets)
    end
    if table_exists?(:titled_images)
      drop_table(:titled_images)
    end

  end
end
