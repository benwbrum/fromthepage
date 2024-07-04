class AddSearchableMetadataToWork < ActiveRecord::Migration[6.0]

  def change
    add_column :works, :searchable_metadata, :text
    Work.all.each do |work|
      work.update_derivatives
      work.update_column(:searchable_metadata, work.searchable_metadata)
    end
  end

end
