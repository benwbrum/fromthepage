class Work::Lib::SetFriendlyFind
  def self.perform(id:)
    work = Work.friendly.find(id, allow_nil: true)

    return work
  end
end
