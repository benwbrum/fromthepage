class BlacklistPageblock < ActiveRecord::Migration[5.2]
  BLACKLIST = [
    'href',
    '.info',
    '.in',
    '.net',
    '.store',
    '.com'
  ]

  def change
    PageBlock.where(:controller => 'admin', :view => 'flag_blacklist').delete_all
  	pb = PageBlock.new
    pb.view = 'flag_blacklist'
    pb.controller = 'admin'
    pb.html = BLACKLIST.join("\n")

    pb.save!
  end
end
