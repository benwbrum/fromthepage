require 'spec_helper'

RSpec.describe ExternalApiRequest, type: :model do
  describe '#params' do
    it 'returns an empty hash when params are blank' do
      expect(described_class.new.params).to eq({})
    end

    it 'serializes and parses hash params' do
      request = described_class.new

      request.params = { 'job' => 'abc123', 'pages' => [1, 2] }

      expect(request[:params]).to eq({ 'job' => 'abc123', 'pages' => [1, 2] }.to_json)
      expect(request.params).to eq('job' => 'abc123', 'pages' => [1, 2])
    end
  end

  describe 'Status.running' do
    it 'returns statuses that still represent active work' do
      expect(described_class::Status.running).to eq(%w[queued running waiting])
    end
  end
end
