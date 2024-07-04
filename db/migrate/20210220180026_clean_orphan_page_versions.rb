class CleanOrphanPageVersions < ActiveRecord::Migration[6.0]

  def change
    PageVersion.where.missing(:page).delete_all
  end

end
