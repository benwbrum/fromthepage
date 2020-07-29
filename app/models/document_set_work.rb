class DocumentSetWork < ApplicationRecord

  self.table_name = "document_sets_works"

  belongs_to :document_set, counter_cache: :works_count, optional: true
  belongs_to :work, optional: true
end
