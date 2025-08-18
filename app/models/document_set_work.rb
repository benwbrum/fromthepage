# == Schema Information
#
# Table name: document_sets_works
#
#  created_at      :datetime
#  updated_at      :datetime
#  document_set_id :integer          not null
#  work_id         :integer          not null
#
# Indexes
#
#  index_document_sets_works_on_work_id_and_document_set_id  (work_id,document_set_id) UNIQUE
#
class DocumentSetWork < ApplicationRecord
  self.table_name = "document_sets_works"

  belongs_to :document_set, counter_cache: :works_count, optional: true
  belongs_to :work, optional: true
end
