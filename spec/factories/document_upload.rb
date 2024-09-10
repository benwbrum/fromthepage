FactoryBot.define do
  factory :document_upload do
    file { Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, 'test_data/uploads/test.pdf'))) }
  end
end
