class Work::UpdateStatisticJob < ApplicationJob
  queue_as :default

  def perform(work_id:)
    work = Work.find(work_id)

    work.work_statistic = WorkStatistic.new unless work.work_statistic
    work.work_statistic.recalculate
  end
end
