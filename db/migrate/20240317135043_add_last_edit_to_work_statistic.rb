class AddLastEditToWorkStatistic < ActiveRecord::Migration[5.0]
  def change
    add_column :work_statistics, :last_edit_at, :datetime
    add_column :pages, :updated_at, :datetime

    # now update the pages updated_at based on the most recent deed for each page
    Page.find_in_batches do |batch|
      batch.each do |page|
        last_deed_date = page.deeds.maximum(:created_at)
        if last_deed_date
          page.update_column(:updated_at, last_deed_date)
        end
      end
    end


    # Loop over every work and update last_edit_at from the maximum of the page updated_at
    Work.all.each do |work|
      last_edit_at = work.pages.maximum(:updated_at)
      work.work_statistic.update(last_edit_at: last_edit_at)
    end
  end
end
