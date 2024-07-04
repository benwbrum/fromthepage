shared_context 'users context' do
  let(:inactive_user) { User.find_by(login: 'ron') }
  let(:rest_user)     { User.find_by(login: 'george') }
  let(:user)          { User.find_by(login: 'eleanor') }
  let(:owner)         { User.find_by(login: 'margaret') }
  let(:new_owner)     { User.find_by(login: 'harry') }
  let(:admin)         { User.find_by(login: 'julia') }
end

RSpec.configure do |config|
  config.include_context 'users context'
end
