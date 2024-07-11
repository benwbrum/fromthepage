class CurrentVersionOnPage < ActiveRecord::Migration[5.0]

  def self.up
    add_column :pages, :page_version_id, :integer

    Page.all.each do |page|
      print "#{page.id} v.s=#{page.page_versions.size}\n"
      versions = page.page_versions
      next unless versions && versions.size > 0

      print "\tv=#{versions[0].page_version}-#{versions[versions.size - 1].page_version}\n"
      top_version = versions[0]
      if top_version
        page.page_version_id = top_version.id
        page.save!
      end
    end
  end

  def self.down
    remove_column :pages, :page_version_id
  end

end
