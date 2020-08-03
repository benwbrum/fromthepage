class DenylistPageblock < ActiveRecord::Migration
  DENYLIST = [
    'href',
    '.info',
    '.in',
    '.net',
    '.store',
    '.com'
  ]

  def change
    PageBlock.where(:controller => 'admin', :view => 'flag_denylist').delete_all
  	pb = PageBlock.new
    pb.view = 'flag_denylist'
    pb.controller = 'admin'
    pb.html = DENYLIST.join("\n")

    pb.save!
  end
end
