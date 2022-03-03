class UpdateCurrentPageVersion < ActiveRecord::Migration[5.0]
  def change
    print "loading\n"
    if Page.count > 0
      max_id = Page.last.id

      0.upto(max_id / 1000) do |i|
        GC.start
        base_id = i*1000
        print "#{base_id} "
        Page.where("id between ? and ?", base_id, base_id+1000).each do |page|
          current_version = page.page_versions.first
          if current_version
            page.update_columns(page_version_id: current_version.id)
          end
        end
      end

      Page.where("id > ?", max_id - 1000).each do |page|
        current_version = page.page_versions.first
        if current_version
          page.update_columns(page_version_id: current_version.id)
        end
      end
    end
  end
end
