require 'faker'
FactoryGirl.define do
  before do
    @user = FactoryGirl.create(:user)
    @transcription = FactoryGirl.create(:transcription)

  end
  #A simple forum
  factory :foro do
  	id  1
    element @transcription
    user  @user
  end
end
