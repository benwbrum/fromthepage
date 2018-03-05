class UpdateNotifications < ActiveRecord::Migration
  def change
    #notifications are created on user save
    unless User.all.empty?
      User.find_each(&:save)
    end
    #owner_stats is false by default - need to initalize to true for owners
    owners = User.where(owner: true)
    unless owners.empty?
      owners.each do |o|
        unless o.notification.nil?
          o.notification.owner_stats = true
          o.notification.save!
        end
      end
    end
  end
end
