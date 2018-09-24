require 'faker'
FactoryBot.define do
  before do
    @user = FactoryBot.create(:user)
    @transcription = FactoryBot.create(:transcription)

  end
  #A simple forum
  factory :foro do
  	id  1
    element @transcription
    user  @user
  end
end
