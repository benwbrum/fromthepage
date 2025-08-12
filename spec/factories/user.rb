FactoryBot.define do
  factory :user do
    sequence(:display_name) { |n| "user_#{n}_login" }
    sequence(:login) { |n| "user_#{n}_login" }
    sequence(:email) { |n| "user_#{n}@sample.com" }
    password { 'password' }
    password_confirmation { 'password' }

    trait :owner do
      owner { true }
      sequence(:display_name) { |n| "owner_#{n}_login" }
      sequence(:login) { |n| "owner_#{n}_login" }
    end

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

    factory :unique_user do
      sequence(:login) { "user_#{SecureRandom.hex(4)}_login" }
      sequence(:email) { "user_#{SecureRandom.hex(4)}@sample.com" }
      password { 'password' }
      password_confirmation { 'password' }

      trait :with_api_key do
        api_key { User.generate_api_key }
      end

      trait :owner do
        owner { true }
      end

      trait :admin do
        admin { true }
      end
    end
  end
end
