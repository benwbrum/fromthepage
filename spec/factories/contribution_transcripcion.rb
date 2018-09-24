require 'faker'
FactoryBot.define do


  before do
    @user = FactoryBot.create(:user)
    @mark = FactoryBot.create(:mark)

  end
  #A simple collection
  factory :contribution do
  	
    text "test"
    type Transcription
    user @user
    mark @mark

  end


end
