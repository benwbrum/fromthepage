FactoryBot.define do
  factory :segmentation_log do
    work_id { association(:work).id }
    page { association(:page, work_id: work_id) }
    model { 'gemini-3.1-pro-preview' }
    status { 'finished' }
    is_first_page_candidate { false }
    metadata { nil }
  end
end
