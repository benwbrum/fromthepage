FactoryGirl.define do

  factory :work_statistic1, class: WorkStatistic do
    work_id 1
    transcribed_pages 0
    annotated_pages 0
    total_pages 0
    blank_pages 0
    incomplete_pages 0
  end

end
