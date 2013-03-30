FactoryGirl.define do

  factory :article1, class: Article do
    title  "joejoejoe"
    lock_version 0
    collection_id 1
  end

  factory :liv, class: Article do
    title "Long Island, Virginia"
    lock_version 115
    collection_id 1
  end


  factory :lin, class: Article do
    title "Long Island, New York"
    lock_version 115
    collection_id 1
  end

  factory :rva, class: Article do
    title "Richmond, Virginia"
    lock_version 115
    collection_id 1
  end


  factory :cent_il, class: Article do
    title "Central Illinois"
    lock_version 115
    collection_id 1
  end

end
