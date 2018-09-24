require 'faker'
FactoryBot.define do


  before do
    @user = FactoryBot.create(:user)
  
  end
  #A simple collection
  factory :translation do
  	id  3
    text "test"
    type Translation
    user @user
  end


end
