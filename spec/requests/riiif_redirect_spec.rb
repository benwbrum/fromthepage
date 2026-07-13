require 'spec_helper'

RSpec.describe 'Riiif image service redirects' do
  it 'redirects bare image service requests to the IIIF info endpoint' do
    get '/image-service/32407848'

    expect(response).to redirect_to('/image-service/32407848/info.json')
  end

  it 'marks bare image service redirects as noindex without blocking link traversal' do
    get '/image-service/32407848'

    expect(response.headers['X-Robots-Tag']).to eq('noindex')
  end
end
