class CleanOrphanPageVersions < ActiveRecord::Migration[6.0]
  def change
    PageVersion.left_outer_joins(:page).where('pages.id is null').delete_all
  end
end
