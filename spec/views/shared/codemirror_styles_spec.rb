require 'spec_helper'

RSpec.describe 'CodeMirror stylesheet' do
  it 'prevents selecting gutter line numbers' do
    # This style is vendored directly from CodeMirror and consumed as a static asset.
    # Reading the source file ensures the non-selectable gutter rule isn't dropped.
    css = File.read(Rails.root.join('app/assets/stylesheets/codemirror/lib/codemirror.css'))

    expect(css).to match(/\.CodeMirror-gutters\s*\{[^}]*-webkit-user-select:\s*none;[^}]*-moz-user-select:\s*none;[^}]*user-select:\s*none;/m)
    expect(css).to match(/\.CodeMirror-linenumber\s*\{[^}]*-webkit-user-select:\s*none;[^}]*-moz-user-select:\s*none;[^}]*user-select:\s*none;/m)
  end
end
