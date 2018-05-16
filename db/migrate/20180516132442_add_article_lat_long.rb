class AddArticleLatLong < ActiveRecord::Migration
  def change
    add_column :articles, :latitude, :decimal, :precision => 10, :scale => 8, :default => nil
    add_column :articles, :longitude, :decimal, :precision => 11, :scale => 8, :default => nil
  end
end
