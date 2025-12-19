class DeleteOrphanedNotes < ActiveRecord::Migration[6.1]
  def change
    Note.left_outer_joins(:page).where('pages.id IS NULL').in_batches(&:destroy_all)
    Note.left_outer_joins(:work).where('works.id IS NULL').in_batches(&:destroy_all)
    Note.left_outer_joins(:collection).where('collections.id IS NULL').in_batches(&:destroy_all)
  end
end
