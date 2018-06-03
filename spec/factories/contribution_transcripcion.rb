require 'faker'
FactoryGirl.define do


  before do
    @user = FactoryGirl.create(:user)
    @mark = FactoryGirl.create(:mark)

  end
  #A simple collection
  factory :contribution do
  	id  1
    text "test"
    type Transcription
    mark @mark
    user @user
  end


end
