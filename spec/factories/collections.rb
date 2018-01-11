require 'faker'
FactoryGirl.define do

  #A simple collection
  factory :collection do
  	id  Random.new(42)
    title ["un titulo","titulo dos","titulo tres"].sample
   
  end


end
