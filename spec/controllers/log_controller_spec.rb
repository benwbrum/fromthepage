require 'spec_helper'

RSpec.describe LogController, type: :controller do
  describe '#log' do
    it 'logs each client-side message fragment' do
      routes.draw { get 'log' => 'log#log' }
      expect(controller).to receive(:debug).with(anything).at_least(:twice).and_call_original

      get :log, params: { message: 'one_two_three' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('')
    end
  end
end
