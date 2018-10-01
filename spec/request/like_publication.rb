require "rails_helper"
require 'json'

RSpec.describe "lilePublicationController", type: :request do

  before do
    @user = FactoryBot.create(:user)
    @publication = FactoryBot.create(:publication)
    @foro = FactoryBot.create(:foro)

  end

  it 'like a publication' do
    puts "-------------------Like a publication-------------------"
    get '/api/publication/like?auth_token='+@user.authentication_token.to_s+'&locale=es&publication_id='+@publication.id.to_s
    json = JSON.parse(response.body)
    puts json['message'];
    expect(json['status']).to eq("OK")
  end



  it 'dislike a publication' do
  	puts "-------------------Dislike a publication-------------------"
  	get '/api/publication/dislike?auth_token='+@user.authentication_token.to_s+'&locale=es&publication_id='+@publication.id.to_s
  	json = JSON.parse(response.body)
  	puts json['message']
    expect(json['status']).to eq("OK")
  end

end
