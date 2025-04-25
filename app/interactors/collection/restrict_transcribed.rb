class Collection::RestrictTranscribed < ApplicationInteractor
  attr_accessor :collection

  def initialize(collection:)
    @collection = collection

    super
  end

  def perform
    @collection.works
               .joins(:work_statistic)
               .where(work_statistics: { complete: 100 }, restrict_scribes: false)
               .update_all(restrict_scribes: true)
  end
end
