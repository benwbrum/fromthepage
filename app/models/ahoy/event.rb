# == Schema Information
#
# Table name: ahoy_events
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  properties :text(65535)
#  time       :datetime
#  user_id    :integer
#  visit_id   :integer
#
# Indexes
#
#  index_ahoy_events_on_name_and_time      (name,time)
#  index_ahoy_events_on_user_id_and_name   (user_id,name)
#  index_ahoy_events_on_visit_id_and_name  (visit_id,name)
#
module Ahoy
  class Event < ActiveRecord::Base
    include Ahoy::Properties

    self.table_name = "ahoy_events"

    belongs_to :visit, optional: true
    belongs_to :user, optional: true

    serialize :properties, JSON
  end
end
