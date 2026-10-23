require 'spec_helper'

RSpec.describe TurboStreamsHelper, type: :helper do
  describe '#turbo_flash' do
    before do
      # Stub the flash_icons helper method
      allow(helper).to receive(:flash_icons).and_return({
        notice: '#icon-check-sign',
        alert: '#icon-warning-sign',
        error: '#icon-remove-sign',
        info: '#icon-warning-sign'
      })

      # Stub the svg_symbol helper
      allow(helper).to receive(:svg_symbol).and_return('<svg></svg>'.html_safe)
    end

    it 'generates turbo stream with accessible flash message for notice' do
      result = helper.turbo_flash('Success message', 'notice')

      # The turbo stream should append a flash message with proper accessibility attributes
      expect(result).to include('turbo-stream action="append" target="flash_wrapper"')
      expect(result).to include('role="status"')
      expect(result).to include('aria-live="polite"')
      expect(result).to include('aria-atomic="true"')
      expect(result).to include('Success message')
    end

    it 'generates turbo stream with accessible flash message for error' do
      result = helper.turbo_flash('Error occurred', 'error')

      expect(result).to include('turbo-stream action="append" target="flash_wrapper"')
      expect(result).to include('role="alert"')
      expect(result).to include('aria-live="assertive"')
      expect(result).to include('aria-atomic="true"')
      expect(result).to include('Error occurred')
    end
  end
end
