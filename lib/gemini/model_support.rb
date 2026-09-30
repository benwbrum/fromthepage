module Gemini
  module ModelSupport
    VERSION_MAP = {
      'gemini-3.1-pro-preview' => 'v1beta',
      'gemini-3-flash-preview' => 'v1beta',
      'gemini-3.5-flash' => 'v1beta',
      'gemini-3.6-flash' => 'v1beta',
      'gemini-3.7-flash' => 'v1beta'
    }.freeze

    REASONING_MAP = VERSION_MAP.keys.to_h { |model| [model, true] }.freeze
  end
end
