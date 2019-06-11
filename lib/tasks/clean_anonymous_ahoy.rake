namespace :fromthepage do
  desc "Clean anonymous ahoy tables"
  task clean_anonymous_ahoy: :environment do
  	Visit.where(:user_id => nil).delete_all
  	Ahoy::Event.where(:user_id => nil).delete_all
  end

end
