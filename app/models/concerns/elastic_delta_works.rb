require 'elastic_util'

# This is a specialized delta concern for tracking permissions updates in
# Elasticsearch when adding works to a public DocumentSet.
#
# When a work is added to a public document set, this concern will update
# the owning document in ES with a fresh `permissions_updated` timestamp.
#
# In doing so, the rake delta index will see the change and refresh the
# permissions for all pages the next time it runs.
module ElasticDeltaWorks
  extend ActiveSupport::Concern

  # Setup hooks
  included do
    if ELASTIC_ENABLED
      after_save :update_permissions
    end
  end

  private

  def update_permissions
    ds = self.document_set;

    if ds[:is_public]
      body = self.work.as_indexed_json().except(:_id) 
      body[:permissions_updated] = Time.now.utc.to_i

      ElasticUtil.safe_index(
        index: 'ftp_work',
        id: self.work[:id],
        body: body
      )
    end
  end
end
