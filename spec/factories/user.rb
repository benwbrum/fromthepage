FactoryBot.define do
  factory :user do
    sequence(:display_name) { |n| "User #{n} Display Name" }
    sequence(:login) { |n| "user_#{n}_login" }
    sequence(:email) { |n| "user_#{n}@sample.com" }
    password { 'password' }
    password_confirmation { 'password' }
  end
end
