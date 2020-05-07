class AhoyActivitySummary < ActiveRecord::Base
    attr_accessible :date, :user_id, :collection_id, :activity, :minutes
end
