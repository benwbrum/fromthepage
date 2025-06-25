# == Schema Information
#
# Table name: honeypot_visits
#
#  id         :bigint           not null, primary key
#  browser    :string(255)
#  ip_address :string(255)      not null
#  ip_subnet  :string(255)      not null
#  user_agent :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  visit_id   :integer
#
# Indexes
#
#  index_honeypot_visits_on_browser                   (browser)
#  index_honeypot_visits_on_ip_address                (ip_address)
#  index_honeypot_visits_on_ip_subnet_and_created_at  (ip_subnet,created_at)
#  index_honeypot_visits_on_visit_id                  (visit_id)
#
# Foreign Keys
#
#  fk_rails_...  (visit_id => visits.id)
#
class HoneypotVisit < ApplicationRecord
  belongs_to :visit, optional: true
end
