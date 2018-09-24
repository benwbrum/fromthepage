require 'faker'
FactoryBot.define do


  before do
    @user = FactoryBot.create(:user)
    @forum = FactoryBot.create(:foro)
  end
  #A simple collection
  factory :publication do
  	id  1
    text "test"
    foro @forum
  end


end
