class CurrentVersionOnPage < ActiveRecord::Migration
  def self.up
    add_column :pages, :page_version_id, :integer

    for page in Page.all
      print "#{page.id} v.s=#{page.page_versions.size}\n"
      versions = page.page_versions
      if versions && versions.size > 0
        print "\tv=#{versions[0].page_version}-#{versions[versions.size-1].page_version}\n"
        top_version = versions[0]
        if top_version
          page.page_version_id = top_version.id
          page.save!
        end
      end
    end
  end

  def self.down
    remove_column :pages, :page_version_id
  end
end
