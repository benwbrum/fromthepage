class DocumentSetWork < ActiveRecord::Base
  
  self.table_name = "document_sets_works"
  
  belongs_to :document_set, counter_cache: :works_count
  belongs_to :work
end
