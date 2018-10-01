require 'faker'
FactoryBot.define do
  #A simple work
	#coordinates = { :x=>23 , :y=>23}
  before do
  #@transcription = FactoryBot.create(:transcription)
  #@user = FactoryBot.create(:user)
  end

  factory :mark do
    text_type {"body"}
    page_id 42
    coordinates "{ :x=>23 , :y=>23}"
    shape_type "polyline"
  #  transcription 2
  #  user 33
    #transcription { Transcription.first || association(:transcription) }
    #user { User.first || association(:user) }
  end


end
