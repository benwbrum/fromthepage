class WorkMetadata < ActiveRecord::Migration
  def self.up
    add_column :works, :physical_description, :text
    add_column :works, :document_history, :text
    add_column :works, :permission_description, :text
    add_column :works, :location_of_composition, :string, :limit => 255
    add_column :works, :author, :string, :limit => 255
    add_column :works, :transcription_conventions, :text
  end

  def self.down
    remove_column :works, :physical_description #binding, condition
    remove_column :works, :document_history #provenance, acquisition, origin
    remove_column :works, :permission_description #what permission was given for this to be transcribed?
    # what permission is given for the transription to be shared?
    remove_column :works, :location_of_composition
    remove_column :works, :author
    remove_column :works, :transcription_conventions

  end
end
