class CorrectDeedCollections < ActiveRecord::Migration
  def change
    Work.all.each { |work| work.update_deed_collection }
  end
end
