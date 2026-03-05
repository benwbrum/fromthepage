class Collection::Lib::SetFriendlyFind
  def self.perform(id:, work_reference: nil)
    collection = Collection.friendly.find(id, allow_nil: true) || DocumentSet.friendly.find(id, allow_nil: true)

    return collection unless work_reference

    # check to make sure URLs haven't gotten scrambled
    if work_reference.collection != collection && !collection.is_a?(DocumentSet)
      # this could be a document set or a bad collection
      return work_reference.collection
    end

    collection
  end
end
