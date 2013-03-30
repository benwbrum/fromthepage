FactoryGirl.define do

  factory :image_set1, class: ImageSet do
    path "/home/fromthepage/fromthepage/releases/20120606195722/public/images/working/35"
    title_format "Untranscribed %Y"
    orientation 0
    original_width 2166
    original_height 3263
    original_to_base_halvings 2
    owner_user_id 1
    step "processing_complete"
    status "complete"
    status_message "cropping files"
    crop_band_start 45
    crop_band_height 80
    rotate_pid 20717
    shrink_pid 20723
    crop_pid 20965
  end

end
