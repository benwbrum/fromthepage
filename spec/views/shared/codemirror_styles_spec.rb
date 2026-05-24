require 'spec_helper'

RSpec.describe 'CodeMirror stylesheet' do
  it 'prevents selecting gutter line numbers' do
    css = File.read(Rails.root.join('app/assets/stylesheets/codemirror/lib/codemirror.css'))

    expect(css).to match(/\.CodeMirror-gutters\s*\{[^}]*user-select:\s*none;/m)
    expect(css).to match(/\.CodeMirror-linenumber\s*\{[^}]*user-select:\s*none;/m)
  end
end
