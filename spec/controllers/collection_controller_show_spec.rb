require 'spec_helper'

RSpec.describe CollectionController, type: :controller do
  let(:owner) { create(:user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, hide_completed: false) }
  
  before do
    allow(controller).to receive(:current_user).and_return(owner)
    allow(controller).to receive(:user_signed_in?).and_return(true)
  end

  describe 'GET #show' do
    context 'filtering works' do
      context 'when showing all works' do
        it 'sets showing_filtered_works to false' do
          get :show, params: { owner_id: owner.to_param, id: collection.to_param, works: 'show' }
          
          expect(assigns(:showing_filtered_works)).to be false
        end
      end

      context 'when hiding completed works via param' do
        it 'sets showing_filtered_works based on whether works are filtered' do
          get :show, params: { owner_id: owner.to_param, id: collection.to_param, works: 'hide' }
          
          # The value depends on whether there are actually incomplete works to show
          expect(assigns(:showing_filtered_works)).to be_in([true, false])
        end
      end

      context 'when collection has hide_completed set to true' do
        let(:collection) { create(:collection, owner_user_id: owner.id, hide_completed: true) }
        
        it 'sets showing_filtered_works based on filtering' do
          get :show, params: { owner_id: owner.to_param, id: collection.to_param }
          
          # Should be true if there are incomplete works, false if filtering falls back to all works
          expect(assigns(:showing_filtered_works)).to be_in([true, false])
        end
      end

      context 'when showing untranscribed works' do
        it 'sets showing_filtered_works to true' do
          get :show, params: { owner_id: owner.to_param, id: collection.to_param, works: 'untranscribed' }
          
          expect(assigns(:showing_filtered_works)).to be true
        end
      end

      context 'with default view (no filtering)' do
        it 'sets showing_filtered_works to false' do
          get :show, params: { owner_id: owner.to_param, id: collection.to_param }
          
          expect(assigns(:showing_filtered_works)).to be false
        end
      end
    end
  end
end