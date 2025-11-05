require 'spec_helper'

RSpec.describe 'static/landing_page', type: :view do
  before do
    # Set up helpers that are needed for the flash partial
    allow(view).to receive(:flash_icons).and_return({
      notice: '#icon-check-sign',
      alert: '#icon-warning-sign',
      error: '#icon-remove-sign',
      info: '#icon-warning-sign'
    })

    allow(view).to receive(:svg_symbol).and_return('<svg></svg>'.html_safe)

    # Mock user authentication status
    allow(view).to receive(:user_signed_in?).and_return(false)
    allow(view).to receive(:signed_in?).and_return(false)
  end

  context 'when flash messages are present' do
    it 'renders flash messages on the landing page' do
      # Set up flash messages
      flash_hash = ActionDispatch::Flash::FlashHash.new
      flash_hash[:notice] = 'Successfully signed in!'
      allow(view).to receive(:flash).and_return(flash_hash)

      render

      expect(rendered).to have_css('div#flash_wrapper')
      expect(rendered).to have_css('div.flash.flash-notice')
      expect(rendered).to include('Successfully signed in!')
    end
  end

  context 'when no flash messages are present' do
    it 'renders the flash wrapper but no flash messages' do
      # Empty flash
      flash_hash = ActionDispatch::Flash::FlashHash.new
      allow(view).to receive(:flash).and_return(flash_hash)

      render

      expect(rendered).to have_css('div#flash_wrapper')
      expect(rendered).not_to have_css('div.flash')
    end
  end
end
