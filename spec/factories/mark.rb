require 'faker'
FactoryBot.define do
  #A simple work
	#coordinates = { :x=>23 , :y=>23}
  before do
    #@user = FactoryBot.create(:user)
    @transcription = FactoryBot.create(:transcription)
    @user = @transcription.user
  end

  factory :mark do
    text_type {"body"}
    page_id 42
    coordinates "{ :x=>23 , :y=>23}"
    shape_type "polyline"
    transcription @transcription
	end

  initialize_with { Mark.new( {:transcription_text => "transcription"} ,@user) }

end
