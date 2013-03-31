FactoryGirl.define do

  factory :titled_image1, class: TitledImage do
    original_file '/fromthepage/images/working/1/img_3556.jpg'
    title_seed '1918-01-03'
    title 'Thursday, January  3, 1918'
    shrink_completed true
    rotate_completed true
    crop_completed true
    association :image_set, factory: :image_set1
    position 4
    lock_version 6
  end

end
