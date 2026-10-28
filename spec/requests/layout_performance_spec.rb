require 'spec_helper'

RSpec.describe 'Application layout performance hints' do
  let(:head) { response.body.split('</head>').first }

  before { get new_user_session_path }

  it 'preconnects to the third-party origins used above the fold' do
    expect(head).to include('rel="preconnect" href="https://fonts.googleapis.com"')
    expect(head).to include('rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"')
    expect(head).to include('rel="preconnect" href="https://cdn.jsdelivr.net" crossorigin="anonymous"')
    expect(head).to include('rel="preconnect" href="https://cdnjs.cloudflare.com" crossorigin="anonymous"')
  end

  it 'requests Google Fonts with font-display swap so text is not blocked on the font download' do
    expect(head).to match(%r{fonts\.googleapis\.com/css\?family=[^"]*display=swap})
  end

  it 'defers the tooltip libraries' do
    expect(head).to match(%r{<script src="https://cdn\.jsdelivr\.net/npm/popper\.js[^"]*" defer="defer"})
    expect(head).to match(%r{<script src="https://cdn\.jsdelivr\.net/npm/tippy\.js[^"]*" defer="defer"})
  end

  it 'does not load the carousel library from the CDN on every page' do
    expect(response.body).not_to include('slick-carousel')
    expect(response.body).not_to include('landing/slick')
  end
end
