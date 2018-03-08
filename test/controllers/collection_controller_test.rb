require 'test_helper'

class Api::CollectionControllerTest < ActionController::TestCase
	

	setup do
   

		@collection = collections(:one)
	end

  def teardown
    # when controller is using cache it may be a good idea to reset it afterwards
    Rails.cache.clear
  end

  test "should update collection" do
    post '/api/collection', {collection: {title: "updated" }}
  
    assert_response :success, message='edit a collection -> Ok'
  end
end

=begin
  test "should create a collection" do
       assert_difference('Collection.count') do
        begin
            post :create, collection: @collection
          rescue  
         end
      end
    assert_response 200, message="create a collection -> OK."
    end

    test "should create a collection" do
    assert_difference('Collection.count') do
      begin
       
        post '/api/collection', params:{ collection: {id:1,title:'mmmmm'}}
      rescue  
      end
    end
    assert_response :error, message= :response
  end
end

  test "should show collection" do
        begin
           get :show, params: {'auth_token'=>'test' },id: @collection
        rescue  
        end
    
      assert_response :success,"show a collection -> Ok"
    end


    test "should update collection" do
      begin
        patch :update, params:{id: 4, collection: {id:4, title: "updated" }}
      rescue  
        end
      assert_response 200,"edit a collection -> Ok"
    end

  test "should destroy collection" do
      assert_difference('Collection.count', -1) do
          begin 
            delete :destroy,id:@collection.id, params: { 'auth_token'=>'test'  }
          rescue  
          end
      end

     # assert_response 200,"delete a collection -> Ok"
    end
=end