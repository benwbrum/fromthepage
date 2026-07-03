require 'spec_helper'

RSpec.describe 'Textdiff plugins' do
  let(:asset_html_diff_path) { Rails.root.join('app/assets/javascripts/textdiff/jquery.pretty-html.diff.js') }
  let(:asset_xml_diff_path) { Rails.root.join('app/assets/javascripts/textdiff/jquery.pretty-xml-diff.js') }
  let(:combined_plugin_path) { Rails.root.join('app/javascript/plugins/textdiff-combined.js') }

  it 'declares HTML diff helper variables locally in the asset pipeline plugin' do
    source = File.read(asset_html_diff_path)

    expect(source).to include('var data, html, operation, tagRegex, text, words;')
  end

  it 'declares XML diff escape patterns locally in the asset pipeline plugin' do
    source = File.read(asset_xml_diff_path)

    expect(source).to include('var data, html, operation, pattern_amp, pattern_gt, pattern_lt, pattern_para, text;')
  end

  it 'declares diff helper variables locally in the combined textdiff plugin' do
    source = File.read(combined_plugin_path)

    expect(source).to include('var data, html, operation, tagRegex, text, words;')
    expect(source).to include('var data, html, operation, pattern_amp, pattern_gt, pattern_lt, pattern_para, text;')
  end
end
