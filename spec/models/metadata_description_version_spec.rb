require 'spec_helper'

RSpec.describe MetadataDescriptionVersion, type: :model do
  describe '#display' do
    it 'combines the date, user display name, and version number' do
      user = build_stubbed(:user, display_name: 'Ada')
      version = described_class.new(user: user, version_number: 3, created_at: Time.zone.local(2024, 1, 2))

      expect(version.display).to eq('Jan 02, 2024 - Ada (3)')
    end
  end
end
