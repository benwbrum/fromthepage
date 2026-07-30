require 'spec_helper'

RSpec.describe ErrorHelper, type: :helper do
  describe '#log_smtp_error' do
    it 'logs the user and exception message' do
      user = double(display_name: 'Test User')
      exception = double(message: 'SMTP unavailable')
      logger = double

      allow(helper).to receive(:logger).and_return(logger)
      expect(logger).to receive(:error).with(include('Document upload by Test User'))
      expect(logger).to receive(:error).with('SMTP Failed: Exception: SMTP unavailable')

      helper.log_smtp_error(exception, user)
    end
  end
end
