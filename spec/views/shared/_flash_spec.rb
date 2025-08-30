require 'spec_helper'

RSpec.describe 'shared/_flash', type: :view do
  before do
    # Stub the flash_icons helper method that would normally be available
    allow(view).to receive(:flash_icons).and_return({
      notice: '#icon-check-sign',
      alert: '#icon-warning-sign',
      error: '#icon-remove-sign',
      info: '#icon-warning-sign'
    })
    
    # Stub the svg_symbol helper that renders the icon
    allow(view).to receive(:svg_symbol).and_return('<svg></svg>'.html_safe)
  end

  context 'for notice flash messages' do
    it 'renders with correct ARIA attributes for status messages' do
      render partial: 'shared/flash', locals: { type: 'notice', message: 'Success!' }
      
      expect(rendered).to have_css('div.flash.flash-notice[role="status"]')
      expect(rendered).to have_css('div[aria-live="polite"]')
      expect(rendered).to have_css('div[aria-atomic="true"]')
      expect(rendered).to include('Success!')
    end
  end

  context 'for info flash messages' do
    it 'renders with correct ARIA attributes for status messages' do
      render partial: 'shared/flash', locals: { type: 'info', message: 'Information message' }
      
      expect(rendered).to have_css('div.flash.flash-info[role="status"]')
      expect(rendered).to have_css('div[aria-live="polite"]')
      expect(rendered).to have_css('div[aria-atomic="true"]')
      expect(rendered).to include('Information message')
    end
  end

  context 'for alert flash messages' do
    it 'renders with correct ARIA attributes for alert messages' do
      render partial: 'shared/flash', locals: { type: 'alert', message: 'Warning!' }
      
      expect(rendered).to have_css('div.flash.flash-alert[role="alert"]')
      expect(rendered).to have_css('div[aria-live="assertive"]')
      expect(rendered).to have_css('div[aria-atomic="true"]')
      expect(rendered).to include('Warning!')
    end
  end

  context 'for error flash messages' do
    it 'renders with correct ARIA attributes for alert messages' do
      render partial: 'shared/flash', locals: { type: 'error', message: 'Error occurred!' }
      
      expect(rendered).to have_css('div.flash.flash-error[role="alert"]')
      expect(rendered).to have_css('div[aria-live="assertive"]')
      expect(rendered).to have_css('div[aria-atomic="true"]')
      expect(rendered).to include('Error occurred!')
    end
  end

  context 'when flash icon is not present' do
    before do
      allow(view).to receive(:flash_icons).and_return({})
    end

    it 'does not render the flash message' do
      render partial: 'shared/flash', locals: { type: 'notice', message: 'Success!' }
      
      expect(rendered).to be_blank
    end
  end

  context 'with Stimulus controller attributes' do
    it 'includes the flash controller and type data attributes' do
      render partial: 'shared/flash', locals: { type: 'notice', message: 'Success!' }
      
      expect(rendered).to have_css('div[data-controller="flash"]')
      expect(rendered).to have_css('div[data-flash-type-value="notice"]')
    end
  end

  context 'with close button' do
    it 'renders a close button with proper data action' do
      render partial: 'shared/flash', locals: { type: 'notice', message: 'Success!' }
      
      expect(rendered).to have_css('a.flash_close[data-action="click->flash#close"]')
      expect(rendered).to include('&times;')
    end
  end
end