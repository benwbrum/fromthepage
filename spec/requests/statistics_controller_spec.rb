require 'spec_helper'

describe StatisticsController, type: :request do
  before do
    @owner = User.create!(login: 'test_owner', email: 'owner@example.com', password: 'password123')
    @collection = Collection.create!(title: 'Test Collection', owner: @owner)
    @work = Work.create!(title: 'Test Work', collection: @collection)
    
    # Create test users and deeds
    @user1 = User.create!(login: 'transcriber1', email: 'transcriber1@example.com', password: 'password123')
    @user2 = User.create!(login: 'transcriber2', email: 'transcriber2@example.com', password: 'password123')
    
    # Create test deeds
    3.times do
      Deed.create!(user: @user1, work: @work, deed_type: DeedType::PAGE_TRANSCRIPTION)
    end
    2.times do
      Deed.create!(user: @user2, work: @work, deed_type: DeedType::PAGE_TRANSCRIPTION)
    end
    1.times do
      Deed.create!(user: @user1, work: @work, deed_type: DeedType::PAGE_EDIT)
    end
  end

  describe 'build_user_array performance optimization' do
    let(:controller) { StatisticsController.new }
    
    before do
      # Set the collection instance variable that the controller expects
      controller.instance_variable_set(:@collection, @collection)
    end

    it 'returns users with correct deed counts for transcription' do
      result = controller.send(:build_user_array, DeedType::PAGE_TRANSCRIPTION)
      
      # Should return users ordered by deed count (desc)
      expect(result.length).to eq(2)
      
      # First user should have 3 deeds
      first_user, first_count = result[0]
      expect(first_user.id).to eq(@user1.id)
      expect(first_count).to eq(3)
      
      # Second user should have 2 deeds  
      second_user, second_count = result[1]
      expect(second_user.id).to eq(@user2.id)
      expect(second_count).to eq(2)
    end

    it 'returns users with correct deed counts for editing' do
      result = controller.send(:build_user_array, DeedType::PAGE_EDIT)
      
      # Should return only user1 who has edit deeds
      expect(result.length).to eq(1)
      
      user, count = result[0]
      expect(user.id).to eq(@user1.id)
      expect(count).to eq(1)
    end

    it 'returns empty array when no users have deeds of specified type' do
      result = controller.send(:build_user_array, DeedType::PAGE_REVIEWED)
      expect(result).to be_empty
    end

    it 'excludes deleted users' do
      # Mark a user as deleted
      @user1.update!(deleted: true)
      
      result = controller.send(:build_user_array, DeedType::PAGE_TRANSCRIPTION)
      
      # Should only return the non-deleted user
      expect(result.length).to eq(1)
      expect(result[0][0].id).to eq(@user2.id)
      expect(result[0][1]).to eq(2)
    end

    it 'handles edge case where user is deleted between queries' do
      # This tests the filter_map logic that handles nil users
      allow(User).to receive(:where).with(id: anything).and_return(
        # Mock a scenario where one user is not found
        double(index_by: { @user2.id => @user2 })
      )
      
      result = controller.send(:build_user_array, DeedType::PAGE_TRANSCRIPTION)
      
      # Should only include users that were actually found
      expect(result.all? { |user, count| user.present? }).to be(true)
    end

    it 'returns actual User objects with expected methods' do
      result = controller.send(:build_user_array, DeedType::PAGE_TRANSCRIPTION)
      
      user = result[0][0]
      expect(user).to be_a(User)
      expect(user).to respond_to(:display_name)
      expect(user).to respond_to(:login)
      expect(user).to respond_to(:email)
      expect(user).to respond_to(:id)
    end
  end

  describe 'performance characteristics' do
    it 'does not load all users when building user arrays' do
      controller = StatisticsController.new
      controller.instance_variable_set(:@collection, @collection)
      
      # Mock User.all to track if it's called
      expect(User).not_to receive(:all)
      
      # Only expect specific user queries
      expect(User).to receive(:where).with(id: anything).and_call_original
      
      controller.send(:build_user_array, DeedType::PAGE_TRANSCRIPTION)
    end
  end
end