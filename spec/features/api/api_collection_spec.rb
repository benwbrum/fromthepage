require 'rails_helper'

describe "Collections Requests", type: :request do

  it 'creates a Collection' do
    previous_length = Collection.count
    post '/api/collection?auth_token="test2',{id:2,name:"Collection test"}

  end


end
