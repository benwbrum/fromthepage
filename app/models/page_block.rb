# == Schema Information
#
# Table name: page_blocks
#
#  id          :integer          not null, primary key
#  controller  :string(255)
#  description :string(255)
#  html        :text(16777215)
#  tag         :string(255)
#  view        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_page_blocks_on_controller_and_view  (controller,view)
#
class PageBlock < ApplicationRecord
  attr_accessor :rendered_html
end
