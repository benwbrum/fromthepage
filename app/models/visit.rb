# == Schema Information
#
# Table name: visits
#
#  id               :integer          not null, primary key
#  browser          :string(255)
#  city             :string(255)
#  country          :string(255)
#  device_type      :string(255)
#  ip               :string(255)
#  landing_page     :text(65535)
#  latitude         :decimal(10, )
#  longitude        :decimal(10, )
#  os               :string(255)
#  postal_code      :string(255)
#  referrer         :text(65535)
#  referring_domain :string(255)
#  region           :string(255)
#  screen_height    :integer
#  screen_width     :integer
#  search_keyword   :string(255)
#  started_at       :datetime
#  user_agent       :text(65535)
#  utm_campaign     :string(255)
#  utm_content      :string(255)
#  utm_medium       :string(255)
#  utm_source       :string(255)
#  utm_term         :string(255)
#  visit_token      :string(255)
#  visitor_token    :string(255)
#  user_id          :integer
#
# Indexes
#
#  index_visits_on_user_id      (user_id)
#  index_visits_on_visit_token  (visit_token) UNIQUE
#
class Visit < ApplicationRecord
  has_many :ahoy_events, class_name: "Ahoy::Event"
  belongs_to :user, optional: true
  has_many :deeds
end
