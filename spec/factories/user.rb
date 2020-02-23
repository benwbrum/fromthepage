FactoryBot.define do
  factory :user do
    sequence(:display_name) { |n| "user_#{n}_login" }
    sequence(:login) { |n| "user_#{n}_login" }
    sequence(:email) { |n| "user_#{n}@sample.com" }
    password { 'password' }
    password_confirmation { 'password' }
  
    factory :owner do
      owner { true }
      sequence(:display_name) { |n| "owner_#{n}_login" }
      sequence(:login) { |n| "owner_#{n}_login" }
    end

    factory :admin do
      admin { true }
      sequence(:display_name) { |n| "admin_#{n}_login" }
      sequence(:login) { |n| "admin_#{n}_login" }
    end
  end
end
