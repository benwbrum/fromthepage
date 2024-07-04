class RenameBlacklistToDenylist < ActiveRecord::Migration[6.0]

  def change
    pb = PageBlock.where(view: 'flag_blacklist').first
    pb.view = 'flag_denylist'
    pb.save
  end

end
