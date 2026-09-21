FactoryBot.define do
  factory :segmentation_log do
    page_id { association(:page).id }
    work_id { association(:work).id }
    model { 'gemini-3.1-pro-preview' }
    status { 'finished' }
    is_first_page_candidate { false }
    metadata { nil }
  end
end
