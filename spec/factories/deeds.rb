FactoryGirl.define do

  factory :deed1, class: Deed do
    deed_type "page_trans"
    page_id 1
    work_id 1
    collection_id 1
    article_id 1
    user_id 1
    note_id 1
  end

end
