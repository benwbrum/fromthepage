require 'spec_helper'

RSpec.describe RegistrationsController, type: :request do
  let(:user_attributes) do
    attributes_for(:unique_user).slice(:login, :email, :password, :password_confirmation).merge(
      real_name: 'Registration Test'
    )
  end

  describe 'POST /users' do
    it 'does not allow registration parameters to create an owner account' do
      attacker_selected_paid_date = 10.years.from_now

      post user_registration_path, params: {
        user: user_attributes.merge(owner: true, paid_date: attacker_selected_paid_date, account_type: 'Staff')
      }

      user = User.find_by!(email: user_attributes[:email])
      expect(user).not_to be_owner
      expect(user.account_type).to be_nil
      expect(user.paid_date).to be_nil
    end
  end

  describe 'POST /users/new_trial' do
    it 'sets trial account privileges and expiration on the server' do
      expected_paid_date = 2.weeks.from_now

      post users_new_trial_path, params: {
        user: user_attributes.merge(owner: false, paid_date: 10.years.from_now, account_type: 'Staff')
      }

      user = User.find_by!(email: user_attributes[:email])
      expect(user).to be_owner
      expect(user.account_type).to eq('Trial')
      expect(user.paid_date).to be_within(1.minute).of(expected_paid_date)
    end

    it 'renders the trial form again when registration fails' do
      post users_new_trial_path, params: {
        user: user_attributes.merge(real_name: '')
      }

      expect(response).to render_template(:new_trial)
    end
  end
end
