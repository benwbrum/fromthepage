class Work::Lib::SetFriendlyFind
  def self.perform(id:, collection_reference: nil)
    work = Work.friendly.find(id, allow_nil: true)

    return work unless collection_reference

    if collection_reference.is_a?(DocumentSet)
      return work if work && work.document_sets.exists?(id: collection_reference.id)

      return collection_reference.works.friendly.find(id, allow_nil: true)
    end

    return work if work && work.collection == collection_reference

    collection_reference.works.friendly.find(id, allow_nil: true)
  end
end
