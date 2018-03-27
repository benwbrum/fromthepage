require 'faker'
FactoryGirl.define do
  #A simple work
	#coordinates = { :x=>23 , :y=>23}
  factory :mark do
  	id  42
    text "mark test"
    text_type "body"
    page_id 42
    #coordinates coordinates
    shape_type "polyline"
   
	end
end
