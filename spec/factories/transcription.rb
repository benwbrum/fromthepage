require 'faker'
FactoryGirl.define do

  #A simple collection
  factory :transcription do
  	id  2
    text "test"
    type Transcription
  end


end
