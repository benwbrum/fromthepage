require 'rails_helper'

RSpec.describe "sc_manifests/show", :type => :view do
  before(:each) do
    @sc_manifest = assign(:sc_manifest, ScManifest.create!(
      :work => nil,
      :sc_collection => nil,
      :sc_id => "Sc",
      :label => "Label",
      :metadata => "MyText",
      :first_sequence_id => "First Sequence",
      :first_sequence_label => "First Sequence Label"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Sc/)
    expect(rendered).to match(/Label/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/First Sequence/)
    expect(rendered).to match(/First Sequence Label/)
  end
end
