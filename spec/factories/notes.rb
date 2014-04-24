FactoryGirl.define do

  factory :note1, class: Note do
    title "Wonder what kind of sausage Carrie made?"
    body "Wonder what kind of sausage Carrie made?"
    user_id 4
    collection_id 1
    work_id 3
    page_id 789
    parent_id 0
    depth 0
  end

end
