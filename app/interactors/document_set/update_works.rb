class DocumentSet::UpdateWorks < ApplicationInteractor
  attr_accessor :document_set

  def initialize(document_set:, work_params:)
    @document_set = document_set
    @work_params  = work_params

    super
  end

  def perform
    work_ids = @document_set.work_ids

    @work_params.each do |id, value|
      work_id = id.to_i
      included = ActiveModel::Type::Boolean.new.cast(value[:included])

      if included
        work_ids << work_id
      else
        work_ids.delete(work_id)
      end
    end

    @document_set.work_ids = work_ids.compact.uniq
    @document_set.save!
  end
end
