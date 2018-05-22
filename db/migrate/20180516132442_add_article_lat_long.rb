class AddArticleLatLong < ActiveRecord::Migration
  def change
    add_column :articles, :latitude, :decimal, :precision => 7, :scale => 5, :default => nil
    add_column :articles, :longitude, :decimal, :precision => 8, :scale => 5, :default => nil
  end
end
