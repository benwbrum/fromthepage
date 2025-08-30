FactoryBot.define do
  factory :document_upload do
    association :user
    association :collection
    file { Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, 'test_data/uploads/test.pdf'))) }
  end
end
