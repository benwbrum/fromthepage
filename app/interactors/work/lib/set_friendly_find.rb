class Work::Lib::SetFriendlyFind
  def self.perform(id:)
    work = Work.friendly.find(id, allow_nil: true)

    work
  end
end
