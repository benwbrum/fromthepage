require 'faker'
FactoryGirl.define do


  before do
    @user = FactoryGirl.create(:user)
    @mark = FactoryGirl.create(:mark)

  end
  #A simple collection
  factory :translation do
  	id  3
    text "test"
    type Translation
    mark @mark
    user @user
  end


end
