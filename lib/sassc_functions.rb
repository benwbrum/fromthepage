require 'sassc'
require 'base64'

module SassC::Script::Functions
  def base64encode(string)
    SassC::Script::Value::String.new(Base64.encode64(string.value))
  end
end
