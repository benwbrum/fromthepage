require 'faker'
FactoryGirl.define do


  before do
    @user = FactoryGirl.create(:user)
    @forum = FactoryGirl.create(:foro)
  end
  #A simple collection
  factory :publication do
  	id  1
    text "test"
    foro @forum
  end


end
