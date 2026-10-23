require 'spec_helper'

describe AiWorkMetadata::Lib::Gemini::GenerateHandler do
  %w[
    gemini-3.1-pro-preview
    gemini-3-flash-preview
    gemini-3.5-flash
    gemini-3.6-flash
    gemini-3.7-flash
  ].each do |model|
    it "includes thought summaries in requests to #{model}" do
      handler = described_class.new(prompt: 'Describe this work', model: model)

      expect(handler.send(:payload)).to include(
        generation_config: { thinking_config: { include_thoughts: true } }
      )
    end
  end
end
