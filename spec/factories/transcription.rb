require 'faker'
FactoryBot.define do

  before do
    @user = FactoryBot.create(:user)

  end
  #A simple collection
  factory :transcription do
  	id  2
    text "test"
    type Transcription
    user @user

  end


end
