class CorrectDeedCollections < ActiveRecord::Migration[5.0]
  def change
    Work.all.each { |work| work.update_deed_collection }
  end
end
