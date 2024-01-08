require 'spec_helper'

RSpec.describe CollectionController, type: :request do
  describe 'GET enable_messageboards' do
    it 'enables messageboards for the collection' do
      user = create(:user)
      collection = create(:collection, owner_user_id: user.id)

      get collection_enable_messageboards_path(:collection_id => collection.friendly_id)
      expect(response).to redirect_to(edit_collection_path(collection.owner, collection))
      expect(collection.reload.messageboards_enabled).to be true
    end
  end
end
